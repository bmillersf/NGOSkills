#!/usr/bin/env python3
"""
Nonprofit Knowledge Engine
==========================
Downloads Salesforce nonprofit documentation, recursively follows links,
compartmentalizes content into NPSP vs NPC (Nonprofit Cloud) tracks,
enhances existing skills with discovered knowledge, and builds a keyword
index for automatic skill routing.

Subcommands:
  scrape   - Download content from seed URLs, recurse embedded links
  process  - Compartmentalize raw content into NPSP / NPC buckets
  enhance  - Enrich skill reference docs with processed content
  index    - Build keyword→skill routing index
  refresh  - Run all of the above in sequence (release-day workflow)
"""

import argparse
import hashlib
import io
import json
import logging
import os
import re
import sys
import time
import urllib.parse
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import requests
from bs4 import BeautifulSoup, Comment
from markdownify import markdownify as md
from tqdm import tqdm

try:
    from pypdf import PdfReader
except ImportError:
    PdfReader = None

# ── Paths ────────────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = REPO_ROOT / "content"
RAW_DIR = CONTENT_DIR / "raw"
NPSP_DIR = CONTENT_DIR / "npsp"
NPC_DIR = CONTENT_DIR / "npc"
SHARED_DIR = CONTENT_DIR / "shared"
INDEX_FILE = CONTENT_DIR / "keyword-index.json"
MANIFEST_FILE = CONTENT_DIR / "manifest.json"
SKILLS_DIR = REPO_ROOT / "skills"
RULES_DIR = REPO_ROOT / ".cursor" / "rules"

for d in [RAW_DIR, NPSP_DIR, NPC_DIR, SHARED_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# ── Logging ──────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("nke")

# ── Seed URLs ────────────────────────────────────────────────────────────────

SEED_URLS = [
    # Marketing / overview pages
    "https://www.salesforce.com/nonprofit/",
    "https://www.salesforce.com/nonprofit/cloud/",
    "https://www.salesforce.com/nonprofit/products/",
    "https://www.salesforce.com/nonprofit/fundraising/",
    "https://www.salesforce.com/nonprofit/case-management/",
    "https://www.salesforce.com/nonprofit/grant-management/",
    "https://www.salesforce.com/nonprofit/marketing/",
    # Help articles (NPC)
    "https://help.salesforce.com/s/articleView?id=sfdo.nonprofit_cloud.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Overview.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Setup.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Fundraising.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Program_and_Case_Management.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Grantmaking.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Outcome_Management.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPC_Volunteer_Management.htm&type=5",
    # Help articles (NPSP)
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Documentation.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Getting_Started.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Configure_Donations.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Recurring_Donations.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Customizable_Rollups.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Households.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Engagement_Plans.htm&type=5",
    "https://help.salesforce.com/s/articleView?id=sfdo.NPSP_Gift_Entry.htm&type=5",
    # PDFs
    "https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/nonprofit_cloud.pdf",
    # GitHub / community
    "https://github.com/SFDO-Community-Sprints",
    "https://github.com/SalesforceFoundation/NPSP",
    "https://github.com/SalesforceFoundation/OutboundFundsModule",
    # Trailhead
    "https://trailhead.salesforce.com/content/learn/trails/get-started-with-nonprofit-cloud",
    "https://trailhead.salesforce.com/content/learn/modules/nonprofit-success-pack-basics",
    # Developer docs
    "https://developer.salesforce.com/docs/industries/nonprofit/overview",
]

ALLOWED_DOMAINS = {
    "www.salesforce.com",
    "help.salesforce.com",
    "developer.salesforce.com",
    "resources.docs.salesforce.com",
    "github.com",
    "trailhead.salesforce.com",
    "architect.salesforce.com",
}

NONPROFIT_PATH_PATTERNS = [
    r"nonprofit",
    r"npsp",
    r"sfdo",
    r"npc",
    r"SalesforceFoundation",
    r"SFDO-Community",
    r"OutboundFunds",
    r"gift.entry",
    r"fundrais",
    r"grantmak",
    r"program.management",
    r"volunteer",
    r"donation",
    r"household",
]

SKIP_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".webp",
    ".mp4", ".webm", ".mp3", ".wav",
    ".woff", ".woff2", ".ttf", ".eot",
    ".zip", ".tar", ".gz", ".dmg", ".exe",
    ".css", ".js", ".json", ".xml",
}

# ── Platform Signals ─────────────────────────────────────────────────────────

NPSP_SIGNALS = [
    r"\bnpsp__\w+",
    r"\bnpe01__\w+",
    r"\bnpo02__\w+",
    r"\bnpe03__\w+",
    r"\bnpe4__\w+",
    r"\bnpe5__\w+",
    r"\boutfunds__\w+",
    r"\bGW_Volunteers__\w+",
    r"\bpmdm__\w+",
    r"\bNPSP\b",
    r"Nonprofit\s+Success\s+Pack",
    r"\bTDTM\b",
    r"Table.Driven\s+Trigger",
    r"\bCRLP\b",
    r"Customizable\s+Rollup",
    r"Household\s+Account",
    r"Household\s+Naming",
    r"npe01__OppPayment",
    r"npsp__Recurring",
    r"npsp__Engagement_Plan",
    r"Outbound\s+Funds\s+Module",
    r"\bOFM\b",
    r"Volunteers\s+for\s+Salesforce",
    r"\bV4S\b",
    r"Program\s+Management\s+Module",
    r"\bPMM\b",
    r"npsp__General_Accounting_Unit",
    r"\bGAU\s+Allocation",
    r"npsp__DataImport",
    r"Batch\s+Gift\s+Entry",
    r"Partial\s+Soft\s+Credit",
    r"Opportunity\s+Contact\s+Role",
    r"npsp__Primary_Contact",
    r"npsp__Acknowledgment",
    r"npsp__Level__c",
    r"Engagement\s+Plan\s+Template",
    r"npsp__Address__c",
    r"Seasonal\s+Address",
    r"NPSP\s+Settings",
    r"NPSP\s+Health\s+Check",
    r"npsp__Error__c",
    r"Individual\s+Bucket",
    r"One.to.One\s+Account",
    r"Matching\s+Gift",
    r"Tribute\s+Gift",
    r"Memorial\s+Gift",
]

NPC_SIGNALS = [
    r"Nonprofit\s+Cloud",
    r"\bNPC\b",
    r"\bAFNP\b",
    r"Advancement\s+for\s+Nonprofits?",
    r"Person\s+Account",
    r"Gift\s+Transaction",
    r"Gift\s+Commitment",
    r"Gift\s+Soft\s+Credit",
    r"Gift\s+Designation",
    r"Gift\s+Transaction\s+Designation",
    r"Payment\s+Instrument",
    r"Funding\s+Award",
    r"Funding\s+Disbursement",
    r"Program\s+Enrollment",
    r"Benefit\s+Disbursement",
    r"Outcome\s+Activity",
    r"Indicator\s+Definition",
    r"Indicator\s+Result",
    r"Party\s+Relationship\s+Group",
    r"Job\s+Position\s+Shift",
    r"Job\s+Position\s+Assignment",
    r"Contact\s+Contact\s+Relationship",
    r"Account\s+Contact\s+Relationship",
    r"Account\s+Account\s+Relationship",
    r"Application\s+object",
    r"Nonprofit\s+Cloud\s+fundraising",
    r"Nonprofit\s+Cloud\s+grantmaking",
    r"Nonprofit\s+Cloud\s+program",
    r"Nonprofit\s+Cloud\s+outcome",
    r"Nonprofit\s+Cloud\s+volunteer",
]

# ── HTTP Session ─────────────────────────────────────────────────────────────

SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
})


# ═══════════════════════════════════════════════════════════════════════════════
#  SCRAPER
# ═══════════════════════════════════════════════════════════════════════════════


def url_to_filename(url: str) -> str:
    """Deterministic filename from URL."""
    h = hashlib.sha256(url.encode()).hexdigest()[:12]
    parsed = urllib.parse.urlparse(url)
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", parsed.path.strip("/"))[:80]
    return f"{parsed.netloc}__{slug}__{h}"


def is_nonprofit_url(url: str) -> bool:
    """Check if URL is related to Salesforce nonprofit content."""
    parsed = urllib.parse.urlparse(url)
    if parsed.netloc not in ALLOWED_DOMAINS:
        return False
    full = parsed.path + "?" + parsed.query if parsed.query else parsed.path
    return any(re.search(p, full, re.IGNORECASE) for p in NONPROFIT_PATH_PATTERNS)


def should_skip_url(url: str) -> bool:
    """Filter out non-content URLs."""
    parsed = urllib.parse.urlparse(url)
    ext = Path(parsed.path).suffix.lower()
    if ext in SKIP_EXTENSIONS:
        return True
    skip_patterns = [
        r"/login", r"/signup", r"/cart", r"/pricing",
        r"/contact-us", r"/privacy", r"/terms",
        r"#", r"javascript:", r"mailto:", r"tel:",
    ]
    return any(re.search(p, url, re.IGNORECASE) for p in skip_patterns)


def fetch_page(url: str, timeout: int = 30) -> Optional[requests.Response]:
    """Fetch a URL with retries and rate limiting."""
    for attempt in range(3):
        try:
            resp = SESSION.get(url, timeout=timeout, allow_redirects=True)
            if resp.status_code == 200:
                return resp
            if resp.status_code == 429:
                wait = int(resp.headers.get("Retry-After", 10))
                log.warning("Rate limited on %s, waiting %ds", url, wait)
                time.sleep(wait)
                continue
            log.warning("HTTP %d for %s", resp.status_code, url)
            return None
        except requests.RequestException as e:
            log.warning("Request error for %s (attempt %d): %s", url, attempt + 1, e)
            time.sleep(2 ** attempt)
    return None


def extract_text_from_html(html: str, url: str) -> str:
    """Extract meaningful text content from HTML, convert to markdown."""
    soup = BeautifulSoup(html, "lxml")

    for tag in soup(["script", "style", "nav", "footer", "header", "noscript"]):
        tag.decompose()
    for comment in soup.find_all(string=lambda t: isinstance(t, Comment)):
        comment.extract()

    main = (
        soup.find("main")
        or soup.find("article")
        or soup.find("div", class_=re.compile(r"content|article|body", re.I))
        or soup.find("div", id=re.compile(r"content|article|body", re.I))
        or soup.body
        or soup
    )

    text = md(str(main), heading_style="ATX", strip=["img"])
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    text = re.sub(r"[ \t]+\n", "\n", text)

    header = f"# Source: {url}\n# Scraped: {datetime.now(timezone.utc).isoformat()}\n\n"
    return header + text.strip()


def extract_text_from_pdf(content: bytes, url: str) -> str:
    """Extract text from a PDF."""
    if PdfReader is None:
        log.warning("pypdf not installed, skipping PDF: %s", url)
        return ""
    reader = PdfReader(io.BytesIO(content))
    pages = []
    for i, page in enumerate(reader.pages):
        text = page.extract_text()
        if text:
            pages.append(f"--- Page {i + 1} ---\n{text}")
    header = f"# Source: {url}\n# Scraped: {datetime.now(timezone.utc).isoformat()}\n\n"
    return header + "\n\n".join(pages)


def extract_links(html: str, base_url: str) -> list[str]:
    """Extract and normalize links from HTML."""
    soup = BeautifulSoup(html, "lxml")
    links = set()
    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        if href.startswith(("#", "javascript:", "mailto:", "tel:")):
            continue
        absolute = urllib.parse.urljoin(base_url, href)
        absolute = absolute.split("#")[0]  # strip fragment
        if absolute:
            links.add(absolute)
    return sorted(links)


def scrape(
    max_depth: int = 2,
    max_pages: int = 200,
    delay: float = 1.0,
    seeds: Optional[list[str]] = None,
):
    """
    Crawl seed URLs, recursively follow nonprofit-relevant links,
    save content to content/raw/.
    """
    if seeds is None:
        seeds = SEED_URLS

    visited: set[str] = set()
    queue: list[tuple[str, int]] = [(url, 0) for url in seeds]
    manifest: dict = {}

    if MANIFEST_FILE.exists():
        try:
            manifest = json.loads(MANIFEST_FILE.read_text())
        except (json.JSONDecodeError, OSError):
            manifest = {}

    progress = tqdm(total=max_pages, desc="Scraping", unit="page")

    while queue and len(visited) < max_pages:
        url, depth = queue.pop(0)

        if url in visited:
            continue
        visited.add(url)

        if should_skip_url(url):
            continue

        parsed = urllib.parse.urlparse(url)
        is_pdf = parsed.path.lower().endswith(".pdf")
        is_seed = url in seeds

        if not is_seed and not is_nonprofit_url(url):
            continue

        fname = url_to_filename(url)
        ext = ".md" if not is_pdf else ".md"
        out_path = RAW_DIR / f"{fname}{ext}"

        cache_entry = manifest.get(url, {})
        cache_age_hours = 0
        if cache_entry.get("scraped_at"):
            try:
                scraped_dt = datetime.fromisoformat(cache_entry["scraped_at"])
                cache_age_hours = (datetime.now(timezone.utc) - scraped_dt).total_seconds() / 3600
            except (ValueError, TypeError):
                cache_age_hours = 9999

        if out_path.exists() and cache_age_hours < 168:  # 7-day cache
            log.debug("Cached: %s", url)
            if depth < max_depth and not is_pdf:
                cached_text = out_path.read_text(errors="replace")
                resp = fetch_page(url)
                if resp and "text/html" in resp.headers.get("content-type", ""):
                    for link in extract_links(resp.text, url):
                        if link not in visited:
                            queue.append((link, depth + 1))
            progress.update(1)
            continue

        log.info("Fetching [depth=%d]: %s", depth, url)
        resp = fetch_page(url)
        if resp is None:
            progress.update(1)
            continue

        content_type = resp.headers.get("content-type", "")
        if is_pdf or "application/pdf" in content_type:
            text = extract_text_from_pdf(resp.content, url)
        elif "text/html" in content_type:
            text = extract_text_from_html(resp.text, url)
            if depth < max_depth:
                for link in extract_links(resp.text, url):
                    if link not in visited:
                        queue.append((link, depth + 1))
        else:
            text = resp.text[:50000]

        if len(text.strip()) > 100:
            out_path.write_text(text, encoding="utf-8")
            manifest[url] = {
                "file": str(out_path.relative_to(REPO_ROOT)),
                "scraped_at": datetime.now(timezone.utc).isoformat(),
                "content_type": content_type.split(";")[0],
                "size_bytes": len(text),
                "depth": depth,
            }
            log.info("Saved: %s (%d bytes)", out_path.name, len(text))

        progress.update(1)
        time.sleep(delay)

    progress.close()
    MANIFEST_FILE.write_text(json.dumps(manifest, indent=2), ensure_ascii=False)
    log.info("Scrape complete: %d pages visited, %d saved", len(visited), len(manifest))


# ═══════════════════════════════════════════════════════════════════════════════
#  PROCESSOR — Compartmentalize NPSP vs NPC
# ═══════════════════════════════════════════════════════════════════════════════


def score_platform(text: str) -> tuple[int, int]:
    """Return (npsp_score, npc_score) for a block of text."""
    npsp = sum(1 for p in NPSP_SIGNALS if re.search(p, text, re.IGNORECASE))
    npc = sum(1 for p in NPC_SIGNALS if re.search(p, text, re.IGNORECASE))
    return npsp, npc


def classify_content(text: str) -> str:
    """Classify text as 'npsp', 'npc', or 'shared'."""
    npsp_score, npc_score = score_platform(text)
    if npsp_score == 0 and npc_score == 0:
        return "shared"
    ratio = npsp_score / max(npc_score, 1)
    if ratio > 2.0:
        return "npsp"
    if ratio < 0.5:
        return "npc"
    return "shared"


def split_into_sections(text: str) -> list[dict]:
    """Split markdown text into headed sections."""
    sections = []
    current_heading = "Introduction"
    current_lines = []

    for line in text.split("\n"):
        heading_match = re.match(r"^(#{1,3})\s+(.+)", line)
        if heading_match:
            if current_lines:
                body = "\n".join(current_lines).strip()
                if body:
                    sections.append({"heading": current_heading, "body": body})
            current_heading = heading_match.group(2)
            current_lines = []
        else:
            current_lines.append(line)

    if current_lines:
        body = "\n".join(current_lines).strip()
        if body:
            sections.append({"heading": current_heading, "body": body})

    return sections


def process_content():
    """
    Read raw content, classify each section as NPSP / NPC / shared,
    and write to the appropriate output directory.
    """
    raw_files = sorted(RAW_DIR.glob("*.md"))
    if not raw_files:
        log.warning("No raw content found. Run 'scrape' first.")
        return

    npsp_sections: list[dict] = []
    npc_sections: list[dict] = []
    shared_sections: list[dict] = []
    stats = Counter()

    for raw_file in tqdm(raw_files, desc="Processing", unit="file"):
        text = raw_file.read_text(errors="replace")
        source_match = re.match(r"^#\s*Source:\s*(.+)$", text, re.MULTILINE)
        source_url = source_match.group(1).strip() if source_match else raw_file.name

        doc_class = classify_content(text)
        stats[f"doc_{doc_class}"] += 1

        sections = split_into_sections(text)

        for section in sections:
            section["source"] = source_url
            section["source_file"] = raw_file.name

            section_class = classify_content(section["body"])
            if section_class == "shared":
                section_class = doc_class

            if section_class == "npsp":
                npsp_sections.append(section)
            elif section_class == "npc":
                npc_sections.append(section)
            else:
                shared_sections.append(section)
            stats[f"section_{section_class}"] += 1

    _write_compartment(NPC_DIR / "npc-knowledge.md", npc_sections, "Nonprofit Cloud (NPC)")
    _write_compartment(NPSP_DIR / "npsp-knowledge.md", npsp_sections, "Nonprofit Success Pack (NPSP)")
    _write_compartment(SHARED_DIR / "shared-knowledge.md", shared_sections, "Shared / Cross-Platform")

    _write_comparison(CONTENT_DIR / "npsp-vs-npc-comparison.md", npsp_sections, npc_sections)

    log.info(
        "Processing complete: %d NPC sections, %d NPSP sections, %d shared",
        len(npc_sections), len(npsp_sections), len(shared_sections),
    )
    log.info("Document-level classification: %s", dict(stats))


def _write_compartment(path: Path, sections: list[dict], title: str):
    """Write compartmentalized knowledge to a markdown file."""
    lines = [
        f"# {title} — Knowledge Base",
        f"",
        f"*Auto-generated by nonprofit-knowledge-engine.py on "
        f"{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}*",
        f"",
        f"**{len(sections)} sections** extracted from Salesforce documentation.",
        f"",
        f"---",
        f"",
    ]

    by_topic = defaultdict(list)
    for s in sections:
        topic = _infer_topic(s["heading"], s["body"])
        by_topic[topic].append(s)

    for topic in sorted(by_topic.keys()):
        lines.append(f"## {topic}")
        lines.append("")
        for s in by_topic[topic]:
            lines.append(f"### {s['heading']}")
            lines.append(f"*Source: {s['source']}*")
            lines.append("")
            lines.append(s["body"])
            lines.append("")
        lines.append("---")
        lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")
    log.info("Wrote %s (%d sections)", path.name, len(sections))


def _write_comparison(path: Path, npsp_sections: list[dict], npc_sections: list[dict]):
    """Generate a side-by-side NPSP vs NPC comparison document."""
    lines = [
        "# NPSP vs Nonprofit Cloud (NPC) — Implementation Guide",
        "",
        "*Auto-generated comparison based on scraped documentation.*",
        "",
        "This document highlights the key differences between NPSP and NPC",
        "to prevent cross-contamination of patterns in implementations.",
        "",
        "---",
        "",
        "## Data Model Differences",
        "",
        "| Concept | NPSP | NPC |",
        "|---------|------|-----|",
        "| Individual | Contact + Household Account | Person Account |",
        "| Donation | Opportunity | Gift Transaction |",
        "| Recurring giving | Recurring Donation (npe03__) | Gift Commitment |",
        "| Soft credits | Partial Soft Credit (npsp__) | Gift Soft Credit |",
        "| Fund accounting | GAU Allocation (npsp__) | Gift Designation |",
        "| Relationships | Relationship (npe4__) + Affiliation (npe5__) | Contact Contact Relationship + Account Contact Relationship |",
        "| Household | Household Account (auto-created) | Party Relationship Group |",
        "| Grant application | Funding Request (outfunds__) | Application |",
        "| Grant award | Funding Request (status=Awarded) | Funding Award |",
        "| Grant payment | Disbursement (outfunds__) | Funding Disbursement |",
        "| Programs | Program (pmdm__) or custom | Program (native) |",
        "| Enrollment | ProgramEngagement (pmdm__) | Program Enrollment |",
        "| Outcomes | Not native | Outcome, Indicator Definition, Indicator Result |",
        "| Volunteers | V4S (GW_Volunteers__) | Job Position, Job Position Shift, Job Position Assignment |",
        "",
        "---",
        "",
        "## Implementation Rules",
        "",
        "### NEVER Mix These Patterns",
        "",
        "- Do NOT use Person Accounts in an NPSP org (unless migrating to NPC)",
        "- Do NOT use Contact+Household Account model in an NPC org",
        "- Do NOT use Opportunity for donations in NPC (use Gift Transaction)",
        "- Do NOT use Gift Transaction in NPSP (use Opportunity)",
        "- Do NOT install NPSP managed package in an NPC org",
        "- Do NOT reference npsp__ namespace objects in NPC implementations",
        "",
        "### NPSP-Only Implementation Rules",
        "",
        "- Always use Household Account model (not One-to-One or Individual Bucket)",
        "- Use TDTM framework for custom trigger management",
        "- Configure CRLP for rollup calculations",
        "- Use npsp__Error__c for error monitoring",
        "- Run NPSP Health Check after configuration changes",
        "- Use Engagement Plans for stewardship automation",
        "- Use Levels for donor recognition tiers",
        "- Use npsp__Address__c for address management (not direct Contact fields)",
        "",
        "### NPC-Only Implementation Rules",
        "",
        "- Use Person Account for all individual constituents",
        "- Use Gift Transaction for all donation types",
        "- Use Gift Commitment + Schedule for recurring giving",
        "- Use native Application/Funding Award for grants (not OFM)",
        "- Use native Program/Program Enrollment for programs (not PMM)",
        "- Use native Outcome/Indicator objects for impact measurement",
        "- Use Party Relationship Group for household management",
        "",
        "---",
        "",
    ]

    npsp_topics = set(_infer_topic(s["heading"], s["body"]) for s in npsp_sections)
    npc_topics = set(_infer_topic(s["heading"], s["body"]) for s in npc_sections)

    lines.append("## Content Coverage")
    lines.append("")
    lines.append(f"- **NPSP-specific sections**: {len(npsp_sections)}")
    lines.append(f"- **NPC-specific sections**: {len(npc_sections)}")
    lines.append(f"- **NPSP topics**: {', '.join(sorted(npsp_topics))}")
    lines.append(f"- **NPC topics**: {', '.join(sorted(npc_topics))}")
    lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")
    log.info("Wrote comparison: %s", path.name)


def _infer_topic(heading: str, body: str) -> str:
    """Infer a broad topic category from heading and body text."""
    text = (heading + " " + body[:500]).lower()
    topics = [
        ("Fundraising & Donations", [
            "fundrais", "donat", "gift", "giving", "campaign", "donor",
            "pledge", "payment", "opportunity", "solicitation",
        ]),
        ("Grants & Grantmaking", [
            "grant", "award", "disbursement", "funding", "applicat",
            "grantmak", "outbound funds", "ofm",
        ]),
        ("Program & Case Management", [
            "program", "case", "enrollment", "service delivery",
            "intake", "referral", "benefit", "wraparound",
        ]),
        ("Outcomes & Impact", [
            "outcome", "indicator", "impact", "measurement", "result",
        ]),
        ("Volunteer Management", [
            "volunteer", "shift", "hours", "assignment", "job position",
        ]),
        ("Data Model & Architecture", [
            "data model", "object", "field", "schema", "relationship",
            "account model", "person account", "household",
        ]),
        ("Configuration & Setup", [
            "setup", "config", "setting", "install", "enable",
            "health check", "tdtm", "trigger handler",
        ]),
        ("Migration", [
            "migrat", "convert", "transition", "npsp to",
        ]),
        ("Reporting & Analytics", [
            "report", "dashboard", "rollup", "crlp", "analytic",
        ]),
        ("Integration", [
            "api", "integration", "connect", "external", "data cloud",
        ]),
        ("Experience Cloud & Portals", [
            "portal", "experience cloud", "community", "site",
        ]),
    ]

    for topic_name, keywords in topics:
        if any(kw in text for kw in keywords):
            return topic_name

    return "General"


# ═══════════════════════════════════════════════════════════════════════════════
#  SKILL ENHANCER
# ═══════════════════════════════════════════════════════════════════════════════


def enhance_skills():
    """
    Read processed NPSP/NPC knowledge and generate enhanced reference docs
    for each nonprofit skill, placed in each skill's references/ directory.
    """
    skill_mappings = {
        "sf-nonprofit-cloud": {
            "sources": ["shared", "npc", "npsp"],
            "topics": ["Data Model & Architecture", "Migration", "General"],
            "output": "scraped-knowledge.md",
        },
        "sf-nonprofit-npsp": {
            "sources": ["npsp"],
            "topics": None,  # all topics
            "output": "scraped-npsp-knowledge.md",
        },
        "sf-nonprofit-fundraising": {
            "sources": ["npc"],
            "topics": ["Fundraising & Donations", "Reporting & Analytics"],
            "output": "scraped-fundraising-knowledge.md",
        },
        "sf-nonprofit-grants": {
            "sources": ["npc"],
            "topics": ["Grants & Grantmaking"],
            "output": "scraped-grants-knowledge.md",
        },
        "sf-nonprofit-program-case": {
            "sources": ["npc"],
            "topics": ["Program & Case Management", "Outcomes & Impact"],
            "output": "scraped-program-case-knowledge.md",
        },
        "sf-nonprofit-experience-cloud": {
            "sources": ["npc", "npsp", "shared"],
            "topics": ["Experience Cloud & Portals"],
            "output": "scraped-experience-cloud-knowledge.md",
        },
        "sf-nonprofit-experience-cloud-ux": {
            "sources": ["shared"],
            "topics": ["Experience Cloud & Portals"],
            "output": "scraped-experience-cloud-ux-knowledge.md",
        },
    }

    knowledge_files = {
        "npc": NPC_DIR / "npc-knowledge.md",
        "npsp": NPSP_DIR / "npsp-knowledge.md",
        "shared": SHARED_DIR / "shared-knowledge.md",
    }

    knowledge: dict[str, str] = {}
    for key, path in knowledge_files.items():
        if path.exists():
            knowledge[key] = path.read_text(errors="replace")
        else:
            knowledge[key] = ""
            log.warning("Knowledge file not found: %s", path)

    for skill_name, config in skill_mappings.items():
        skill_dir = SKILLS_DIR / skill_name
        if not skill_dir.exists():
            log.warning("Skill directory not found: %s", skill_dir)
            continue

        refs_dir = skill_dir / "references"
        refs_dir.mkdir(exist_ok=True)

        relevant_content = []
        for source_key in config["sources"]:
            text = knowledge.get(source_key, "")
            if not text:
                continue

            if config["topics"]:
                sections = split_into_sections(text)
                for section in sections:
                    topic = _infer_topic(section["heading"], section["body"])
                    if topic in config["topics"]:
                        relevant_content.append(section)
            else:
                sections = split_into_sections(text)
                relevant_content.extend(sections)

        if not relevant_content:
            log.info("No relevant content for %s", skill_name)
            continue

        out_path = refs_dir / config["output"]
        lines = [
            f"# {skill_name} — Scraped Knowledge",
            "",
            f"*Auto-generated by nonprofit-knowledge-engine.py on "
            f"{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}*",
            "",
            f"**{len(relevant_content)} sections** from Salesforce documentation, "
            f"filtered for this skill's domain.",
            "",
            "---",
            "",
        ]

        for section in relevant_content:
            lines.append(f"### {section['heading']}")
            if section.get("source"):
                lines.append(f"*Source: {section['source']}*")
            lines.append("")
            body = section["body"]
            if len(body) > 3000:
                body = body[:3000] + "\n\n*(truncated for skill reference)*"
            lines.append(body)
            lines.append("")
            lines.append("---")
            lines.append("")

        out_path.write_text("\n".join(lines), encoding="utf-8")
        log.info("Enhanced %s: %d sections → %s", skill_name, len(relevant_content), out_path.name)


# ═══════════════════════════════════════════════════════════════════════════════
#  KEYWORD INDEX BUILDER
# ═══════════════════════════════════════════════════════════════════════════════


SKILL_KEYWORD_SEEDS = {
    "sf-nonprofit-cloud": [
        "nonprofit cloud", "npc", "npsp", "nonprofit success pack",
        "nonprofit salesforce", "person account vs contact",
        "npsp to npc migration", "nonprofit platform",
        "salesforce nonprofit", "salesforce.org",
    ],
    "sf-nonprofit-npsp": [
        "npsp", "nonprofit success pack", "npsp__", "npe01__", "npo02__",
        "npe03__", "npe4__", "npe5__", "tdtm", "crlp",
        "customizable rollup", "household account", "household naming",
        "npsp settings", "engagement plan", "donor level",
        "npsp health check", "batch gift entry", "data import",
        "gau allocation", "general accounting unit",
        "partial soft credit", "recurring donation",
        "matching gift", "tribute gift", "memorial gift",
        "opportunity naming", "seasonal address",
        "manage households", "npsp error", "opp payment",
        "contact merge", "account merge",
        "outbound funds module", "ofm", "volunteers for salesforce",
        "v4s", "program management module", "pmm",
        "outfunds__", "gw_volunteers__", "pmdm__",
        "individual bucket", "one-to-one account",
        "npsp batch", "lead conversion npsp",
    ],
    "sf-nonprofit-fundraising": [
        "gift transaction", "gift commitment", "gift soft credit",
        "gift designation", "payment instrument", "donor management",
        "gift entry", "fundraising", "donation", "campaign",
        "donor lifecycle", "major gift", "planned giving",
        "gift processing", "recurring giving", "gift schedule",
        "npc fundraising", "nonprofit cloud fundraising",
        "annual fund", "capital campaign", "pledge",
        "donor stewardship", "donor retention",
    ],
    "sf-nonprofit-grants": [
        "grant management", "grantmaking", "application",
        "funding award", "funding disbursement", "budget",
        "grant application", "review process", "grant compliance",
        "disbursement schedule", "funding program",
        "grant pipeline", "award management", "funder reporting",
        "npc grantmaking", "nonprofit cloud grants",
    ],
    "sf-nonprofit-program-case": [
        "program management", "program enrollment", "benefit",
        "benefit disbursement", "case management", "intake",
        "service delivery", "referral", "outcome tracking",
        "outcome management", "indicator definition",
        "indicator result", "outcome activity",
        "wraparound services", "program design",
        "npc program", "nonprofit cloud program",
        "client management", "social services",
    ],
    "sf-nonprofit-experience-cloud": [
        "donor portal", "volunteer portal", "client portal",
        "grantee portal", "nonprofit portal", "community site",
        "self-service portal", "sharing rules nonprofit",
        "guest access nonprofit", "lwr site nonprofit",
        "experience cloud nonprofit",
    ],
    "sf-nonprofit-experience-cloud-ux": [
        "portal branding", "portal design", "portal ux",
        "portal ui", "portal navigation", "portal accessibility",
        "portal wireframe", "nonprofit portal design",
        "donor experience", "volunteer experience",
    ],
}


def extract_keywords_from_content(text: str) -> list[str]:
    """Extract meaningful multi-word phrases and terms from content."""
    phrases = set()

    sf_terms = re.findall(
        r"\b(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,4})\b",
        text,
    )
    for term in sf_terms:
        if len(term) > 5 and not term.startswith(("The ", "This ", "That ", "When ", "How ")):
            phrases.add(term.lower())

    namespace_terms = re.findall(r"\b\w+__\w+__c?\b", text, re.IGNORECASE)
    for term in namespace_terms:
        phrases.add(term.lower())

    for term in ["Person Account", "Household Account", "Gift Transaction",
                 "Gift Commitment", "Gift Soft Credit", "Gift Designation",
                 "Payment Instrument", "Funding Award", "Funding Disbursement",
                 "Program Enrollment", "Benefit Disbursement", "Outcome Activity",
                 "Indicator Definition", "Indicator Result", "Party Relationship Group",
                 "Recurring Donation", "GAU Allocation", "Engagement Plan",
                 "Partial Soft Credit", "Volunteer Job", "Volunteer Shift"]:
        if term.lower() in text.lower():
            phrases.add(term.lower())

    return sorted(phrases)


def build_keyword_index():
    """
    Build a keyword→skill routing index from:
    1. Seed keywords per skill
    2. Keywords extracted from compartmentalized content
    3. Signal patterns from the platform classifiers
    """
    index: dict[str, dict] = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "description": (
            "Keyword-to-skill routing index for automatic nonprofit skill triggering. "
            "When a user prompt contains any of these keywords, the matched skill(s) "
            "should be applied automatically."
        ),
        "skills": {},
    }

    for skill_name, seeds in SKILL_KEYWORD_SEEDS.items():
        skill_keywords = set(kw.lower() for kw in seeds)

        knowledge_sources = []
        if "npsp" in skill_name:
            knowledge_sources.append(NPSP_DIR / "npsp-knowledge.md")
        elif "cloud" in skill_name and "experience" not in skill_name:
            knowledge_sources.extend([
                NPC_DIR / "npc-knowledge.md",
                NPSP_DIR / "npsp-knowledge.md",
                SHARED_DIR / "shared-knowledge.md",
            ])
        else:
            knowledge_sources.append(NPC_DIR / "npc-knowledge.md")

        for kf in knowledge_sources:
            if kf.exists():
                text = kf.read_text(errors="replace")
                extracted = extract_keywords_from_content(text[:50000])
                skill_keywords.update(extracted[:50])

        index["skills"][skill_name] = {
            "keywords": sorted(skill_keywords),
            "keyword_count": len(skill_keywords),
        }

    INDEX_FILE.write_text(json.dumps(index, indent=2, ensure_ascii=False), encoding="utf-8")
    log.info("Keyword index built: %s", INDEX_FILE)

    total = sum(s["keyword_count"] for s in index["skills"].values())
    log.info("Total keywords: %d across %d skills", total, len(index["skills"]))

    _generate_auto_router_rule(index)

    return index


def _generate_auto_router_rule(index: dict):
    """Generate a Cursor rule file that embeds the keyword index for auto-routing."""
    RULES_DIR.mkdir(parents=True, exist_ok=True)
    rule_path = RULES_DIR / "nonprofit-auto-router.md"

    lines = [
        "---",
        "description: Auto-routes nonprofit prompts to the correct skill based on keyword matching",
        "globs:",
        "alwaysApply: true",
        "---",
        "",
        "# Nonprofit Skill Auto-Router",
        "",
        "When the user's prompt contains keywords related to Salesforce nonprofit features,",
        "automatically apply the matching skill(s) from the keyword index below.",
        "",
        "## Routing Rules",
        "",
        "1. Scan the user prompt for keywords listed under each skill",
        "2. If keywords from a single skill are found, apply that skill",
        "3. If keywords from multiple skills match, apply the most specific skill first",
        "4. Always determine NPC vs NPSP before generating code or configuration",
        "5. If both NPC and NPSP keywords appear, apply sf-nonprofit-cloud first (it routes)",
        "",
        "## Priority Order",
        "",
        "When multiple skills match, prefer in this order:",
        "1. sf-nonprofit-cloud (platform router — always apply first if ambiguous)",
        "2. sf-nonprofit-npsp (NPSP-specific work)",
        "3. sf-nonprofit-fundraising (NPC fundraising)",
        "4. sf-nonprofit-grants (NPC grants)",
        "5. sf-nonprofit-program-case (NPC programs)",
        "6. sf-nonprofit-experience-cloud (portals)",
        "7. sf-nonprofit-experience-cloud-ux (portal design)",
        "",
        "## CRITICAL: Platform Separation",
        "",
        "- NPSP keywords → route to sf-nonprofit-npsp",
        "- NPC/Nonprofit Cloud keywords → route to sf-nonprofit-fundraising / sf-nonprofit-grants / sf-nonprofit-program-case",
        "- NEVER mix NPSP and NPC object models in the same implementation",
        "- When in doubt, ask: \"Is this org running NPSP or Nonprofit Cloud?\"",
        "",
        "## Keyword Index",
        "",
    ]

    for skill_name, skill_data in sorted(index.get("skills", {}).items()):
        keywords = skill_data.get("keywords", [])
        lines.append(f"### {skill_name}")
        lines.append("")

        chunks = [keywords[i:i + 8] for i in range(0, len(keywords), 8)]
        for chunk in chunks:
            lines.append(f"  {', '.join(chunk)}")
        lines.append("")

    lines.extend([
        "---",
        "",
        f"*Generated by nonprofit-knowledge-engine.py on "
        f"{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}*",
    ])

    rule_path.write_text("\n".join(lines), encoding="utf-8")
    log.info("Auto-router rule written: %s", rule_path)


# ═══════════════════════════════════════════════════════════════════════════════
#  REFRESH (orchestrator)
# ═══════════════════════════════════════════════════════════════════════════════


def refresh(max_depth: int = 2, max_pages: int = 200, delay: float = 1.0):
    """Run the full pipeline: scrape → process → enhance → index."""
    log.info("=" * 60)
    log.info("NONPROFIT KNOWLEDGE REFRESH")
    log.info("=" * 60)

    log.info("\n── Phase 1: Scrape ──")
    scrape(max_depth=max_depth, max_pages=max_pages, delay=delay)

    log.info("\n── Phase 2: Process (NPSP vs NPC compartmentalization) ──")
    process_content()

    log.info("\n── Phase 3: Enhance Skills ──")
    enhance_skills()

    log.info("\n── Phase 4: Build Keyword Index ──")
    build_keyword_index()

    log.info("\n── Refresh Complete ──")
    log.info("Content directory: %s", CONTENT_DIR)
    log.info("Keyword index: %s", INDEX_FILE)
    log.info("Auto-router rule: %s", RULES_DIR / "nonprofit-auto-router.md")


# ═══════════════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════════════


def main():
    parser = argparse.ArgumentParser(
        description="Nonprofit Knowledge Engine — scrape, process, enhance, and index Salesforce nonprofit content",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s scrape                       # Download content from seed URLs
  %(prog)s scrape --max-depth 3         # Deeper recursion
  %(prog)s process                      # Compartmentalize NPSP vs NPC
  %(prog)s enhance                      # Enrich skill reference docs
  %(prog)s index                        # Build keyword routing index
  %(prog)s refresh                      # All of the above
  %(prog)s refresh --max-pages 500      # Full refresh with more pages
        """,
    )

    sub = parser.add_subparsers(dest="command", required=True)

    scrape_p = sub.add_parser("scrape", help="Download content from seed URLs")
    scrape_p.add_argument("--max-depth", type=int, default=2, help="Max link recursion depth (default: 2)")
    scrape_p.add_argument("--max-pages", type=int, default=200, help="Max pages to fetch (default: 200)")
    scrape_p.add_argument("--delay", type=float, default=1.0, help="Delay between requests in seconds (default: 1.0)")
    scrape_p.add_argument("--url", action="append", help="Additional seed URL(s)")

    sub.add_parser("process", help="Compartmentalize raw content into NPSP / NPC buckets")

    sub.add_parser("enhance", help="Enrich skill reference docs with processed content")

    sub.add_parser("index", help="Build keyword → skill routing index")

    refresh_p = sub.add_parser("refresh", help="Run full pipeline: scrape → process → enhance → index")
    refresh_p.add_argument("--max-depth", type=int, default=2)
    refresh_p.add_argument("--max-pages", type=int, default=200)
    refresh_p.add_argument("--delay", type=float, default=1.0)

    args = parser.parse_args()

    if args.command == "scrape":
        extra = args.url or []
        scrape(max_depth=args.max_depth, max_pages=args.max_pages, delay=args.delay,
               seeds=SEED_URLS + extra if extra else None)
    elif args.command == "process":
        process_content()
    elif args.command == "enhance":
        enhance_skills()
    elif args.command == "index":
        build_keyword_index()
    elif args.command == "refresh":
        refresh(max_depth=args.max_depth, max_pages=args.max_pages, delay=args.delay)


if __name__ == "__main__":
    main()
