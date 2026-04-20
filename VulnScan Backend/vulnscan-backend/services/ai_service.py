"""AI-powered vulnerability analysis using Claude."""

import anthropic
import json
import re
from typing import Optional
from models.vulnerability import Vulnerability, SeverityLevel
from core.config import settings


async def analyze_vulnerability(vuln: Vulnerability) -> None:
    """
    Analyze a vulnerability using Claude AI.
    Enriches vuln with ai_explanation and ai_fix_suggestion.
    Only processes Critical and High severity vulnerabilities.
    
    Args:
        vuln: Vulnerability object to analyze (modified in-place)
        
    Returns:
        None (modifies vuln object directly)
    """
    # Skip if not Critical/High or already has AI content
    if vuln.severity not in [SeverityLevel.CRITICAL, SeverityLevel.HIGH]:
        return
    
    if not settings.CLAUDE_API_KEY:
        print("⚠️ CLAUDE_API_KEY not configured, skipping AI analysis")
        return
    
    try:
        client = anthropic.Anthropic(api_key=settings.CLAUDE_API_KEY)
        
        # Build user prompt with vulnerability details
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
            messages=[
                {"role": "user", "content": user_prompt}
            ]
        )
        
        # Parse response
        response_text = message.content[0].text
        
        # Try to extract JSON from response
        try:
            # Look for JSON in the response
            json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if json_match:
                response_json = json.loads(json_match.group())
                vuln.ai_explanation = response_json.get("explanation")
                vuln.ai_fix_suggestion = response_json.get("fix_suggestion")
                vuln.has_ai_content = True
                print(f"✨ AI analysis complete for {vuln.type}")
            else:
                # If no JSON found, use raw response
                vuln.ai_explanation = response_text[:500]
                vuln.has_ai_content = True
        except json.JSONDecodeError:
            # If JSON parsing fails, use raw response
            vuln.ai_explanation = response_text[:500]
            vuln.has_ai_content = True
            
    except anthropic.APIError as e:
        print(f"❌ Claude API error for {vuln.type}: {e}")
        # Leave AI fields as None, don't crash
        vuln.ai_explanation = None
        vuln.ai_fix_suggestion = None
        vuln.has_ai_content = False
    except Exception as e:
        print(f"❌ Unexpected error in AI analysis for {vuln.type}: {e}")
        vuln.ai_explanation = None
        vuln.ai_fix_suggestion = None
        vuln.has_ai_content = False


async def analyze_vulnerabilities(vulnerabilities: list, scan_type: str) -> str:
    """
    Use Claude/GPT to provide advanced analysis and remediation guidance
    for found vulnerabilities.
    
    Deprecated: Use analyze_vulnerability() instead for individual vulnerabilities.
    """
    # TODO: Implement Claude/OpenAI integration
    return ""


async def get_remediation_steps(vulnerability_type: str) -> Optional[str]:
    """
    Get AI-generated remediation steps for a vulnerability type.
    
    Deprecated: Use analyze_vulnerability() instead.
    """
    # TODO: Implement AI remediation generation
    return None
