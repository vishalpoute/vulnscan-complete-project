"""GitHub repository cloning utility."""

import subprocess
import shutil
from pathlib import Path
from typing import Optional
from core.config import settings


class GitCloneError(Exception):
    """Raised when GitHub cloning fails."""
    pass


async def clone_repository(
    repo_url: str,
    scan_id: str,
    github_token: Optional[str] = None,
) -> str:
    """
    Clone a GitHub repository into a temporary directory.
    
    Args:
        repo_url: GitHub repository URL (https://github.com/owner/repo)
        scan_id: Unique scan ID for temp directory
        github_token: Optional OAuth token for private repos
        
    Returns:
        Path to cloned repository (/tmp/{scan_id})
        
    Raises:
        GitCloneError: If cloning fails
    """
    clone_path = Path(settings.TEMP_SCAN_DIR) / scan_id
    
    try:
        # Clean up if directory already exists
        if clone_path.exists():
            shutil.rmtree(clone_path)
        
        clone_path.mkdir(parents=True, exist_ok=True)
        
        # Prepare clone URL with token if provided (for private repos)
        if github_token:
            # Insert token into URL: https://token@github.com/owner/repo
            if repo_url.startswith("https://"):
                clone_url = repo_url.replace("https://", f"https://{github_token}@")
            else:
                raise GitCloneError(f"Only HTTPS URLs supported. Got: {repo_url}")
        else:
            clone_url = repo_url
        
        # Run git clone with timeout
        result = subprocess.run(
            ["git", "clone", "--depth", "1", clone_url, str(clone_path)],
            capture_output=True,
            text=True,
            timeout=60,
        )
        
        if result.returncode != 0:
            raise GitCloneError(
                f"Git clone failed: {result.stderr or result.stdout}"
            )
        
        return str(clone_path)
        
    except subprocess.TimeoutExpired:
        raise GitCloneError(f"Git clone timed out (60s) for {repo_url}")
    except FileNotFoundError:
        raise GitCloneError("Git command not found. Install Git to enable scanning.")
    except Exception as e:
        raise GitCloneError(f"Failed to clone repository: {str(e)}")


async def cleanup_repository(scan_id: str) -> None:
    """
    Delete temporary repository directory after scan completes.
    
    Args:
        scan_id: Unique scan ID for temp directory
    """
    clone_path = Path(settings.TEMP_SCAN_DIR) / scan_id
    
    try:
        if clone_path.exists():
            shutil.rmtree(clone_path)
            print(f"✓ Cleaned up repository at {clone_path}")
    except Exception as e:
        print(f"⚠ Failed to clean up repository at {clone_path}: {e}")
