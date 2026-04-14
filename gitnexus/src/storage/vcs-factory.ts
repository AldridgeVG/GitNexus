/**
 * VCS Factory
 *
 * Factory function to detect and create the appropriate VCS adapter.
 */

import type { VCSAdapter, VCSType } from './vcs.js';
import { GitAdapter } from './vcs-git.js';
import { SVNAdapter } from './vcs-svn.js';
import { hasGitDir, hasSVNDir, getGitRoot, getSVNRoot, detectVCSType } from './vcs.js';

export { hasGitDir, hasSVNDir, getGitRoot, getSVNRoot, detectVCSType };

/**
 * Create a VCS adapter for the given path
 *
 * Automatically detects the VCS type and returns the appropriate adapter.
 * Returns null if no supported VCS is detected.
 */
export function createVCSAdapter(repoPath: string): VCSAdapter | null {
  const vcsType = detectVCSType(repoPath);

  switch (vcsType) {
    case 'git':
      return new GitAdapter(repoPath);
    case 'svn':
      return new SVNAdapter(repoPath);
    default:
      return null;
  }
}

/**
 * Find the VCS repository root from any path inside
 */
export function getVCSRoot(fromPath: string): { root: string; type: VCSType } | null {
  // Try Git first
  const gitRoot = getGitRoot(fromPath);
  if (gitRoot) {
    return { root: gitRoot, type: 'git' };
  }

  // Then try SVN
  const svnRoot = getSVNRoot(fromPath);
  if (svnRoot) {
    return { root: svnRoot, type: 'svn' };
  }

  return null;
}

/**
 * Check if a path has any supported VCS directory
 */
export function hasVCSDir(dirPath: string): boolean {
  return hasGitDir(dirPath) || hasSVNDir(dirPath);
}

/**
 * Get the appropriate ignore file for the VCS type
 */
export function getIgnoreFiles(vcsType: VCSType): string[] {
  switch (vcsType) {
    case 'git':
      return ['.gitignore', '.gitnexusignore'];
    case 'svn':
      // SVN doesn't have a standard ignore file in the working copy
      // but we can still support .gitnexusignore for consistency
      return ['.gitnexusignore'];
    default:
      return ['.gitnexusignore'];
  }
}
