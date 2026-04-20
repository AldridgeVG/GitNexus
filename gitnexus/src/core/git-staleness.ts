/**
 * VCS staleness detection (used by MCP resources, group status, etc.).
 * Lives in core/ so application code does not depend on the MCP package layer.
 *
 * This module provides backward-compatible staleness checking for both Git and SVN.
 * New code should use the VCSAdapter.checkStaleness() method directly.
 */

import { createVCSAdapter, getVCSRoot } from '../storage/vcs-factory.js';
import type { StalenessInfo } from '../storage/vcs.js';
export type { StalenessInfo };

/**
 * Check how many commits/revisions the index is behind HEAD.
 *
 * @param repoPath - Path to the repository (or any path inside it)
 * @param lastRevision - The last indexed revision (commit hash for Git, rev number for SVN)
 * @returns Staleness information
 *
 * @deprecated Prefer using VCSAdapter.checkStaleness() for new code
 */
export function checkStaleness(repoPath: string, lastRevision: string): StalenessInfo {
  // Resolve the actual VCS root first — repoPath may be a subdirectory
  const root = getVCSRoot(repoPath);
  const adapter = root ? createVCSAdapter(root.root) : null;

  if (!adapter) {
    // No VCS detected, can't determine staleness
    return { isStale: false, commitsBehind: 0 };
  }

  return adapter.checkStaleness(lastRevision);
}

/**
 * Legacy function for backward compatibility.
 * Alias for checkStaleness().
 */
export function checkGitStaleness(repoPath: string, lastCommit: string): StalenessInfo {
  return checkStaleness(repoPath, lastCommit);
}
