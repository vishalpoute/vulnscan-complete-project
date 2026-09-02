"""AI-powered vulnerability analysis using Claude."""

import asyncio
import json
import re
from typing import Optional

from core.config import settings
from models.vulnerability import SeverityLevel, Vulnerability


def _parse_ai_response(response_text: str, vuln: Vulnerability) -> None:
    """Parse Claude JSON response into a Vulnerability object."""
    try:
        json_match = re.search(r"\{.*\}", response_text, re.DOTALL)
        if json_match:
            response_json = json.loads(json_match.group())
            vuln.ai_explanation = response_json.get("explanation")
            vuln.ai_fix_suggestion = response_json.get("fix_suggestion")
        else:
            vuln.ai_explanation = response_text[:500]
        vuln.has_ai_content = True
    except json.JSONDecodeError:
        vuln.ai_explanation = response_text[:500]
        vuln.has_ai_content = True


def _call_claude(vuln: Vulnerability) -> str:
    """Call Claude synchronously; executed in a worker thread."""
    import anthropic

    client = anthropic.Anthropic(api_key=settings.CLAUDE_API_KEY)
    user_prompt = f"""
Analyze this security vulnerability:

**Title:** {vuln.title}
**Type:** {vuln.type}
**Severity:** {vuln.severity}
**File:** {vuln.file_path or "Unknown"}
**Line:** {vuln.line_number or "Unknown"}

**Code Snippet:**
```
{vuln.code_snippet or "Not available"}
```

**Description:** {vuln.description}
"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=500,
        system="""You are a senior security engineer. Given a vulnerability found in code, provide:
1. A clear explanation in 2-3 sentences (what it is, why it is dangerous)
2. A concrete code fix with before/after example
Keep response under 200 words. Be specific to the code shown.

Format your response as JSON with two fields:
- "explanation": string (2-3 sentences explaining the vulnerability)
- "fix_suggestion": string (before/after code example)""",
        messages=[{"role": "user", "content": user_prompt}],
    )
    return message.content[0].text


async def analyze_vulnerability(vuln: Vulnerability) -> None:
    """Enrich a critical/high vulnerability with Claude analysis when configured."""
    if vuln.severity not in [SeverityLevel.CRITICAL, SeverityLevel.HIGH, "critical", "high"]:
        return

    if not settings.CLAUDE_API_KEY:
        print("⚠️ CLAUDE_API_KEY not configured, skipping AI analysis")
        return

    try:
        response_text = await asyncio.to_thread(_call_claude, vuln)
        _parse_ai_response(response_text, vuln)
        print(f"✨ AI analysis complete for {vuln.type}")
    except ImportError:
        print("⚠️ anthropic package is not installed, skipping AI analysis")
    except Exception as exc:
        print(f"❌ AI analysis error for {vuln.type}: {exc}")
        vuln.ai_explanation = None
        vuln.ai_fix_suggestion = None
        vuln.has_ai_content = False


async def analyze_vulnerabilities(vulnerabilities: list, scan_type: str) -> str:
    """Deprecated compatibility wrapper for older callers."""
    for vulnerability in vulnerabilities:
        if isinstance(vulnerability, Vulnerability):
            await analyze_vulnerability(vulnerability)
    return ""


async def get_remediation_steps(vulnerability_type: str) -> Optional[str]:
    """Deprecated compatibility wrapper for older callers."""
    return None
