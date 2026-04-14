/**
 * Status Command
 *
 * Shows the indexing status of the current repository.
 */

import path from 'path';
import { findRepo, getStoragePaths, hasKuzuIndex, getVCSType } from '../storage/repo-manager.js';
import { createVCSAdapter, getVCSRoot } from '../storage/vcs-factory.js';

export const statusCommand = async (repoPathArg?: string) => {
  const cwd = repoPathArg ? path.resolve(repoPathArg) : process.cwd();

  const vcsAdapter = createVCSAdapter(cwd);
  if (!vcsAdapter) {
    console.log('Not a version control repository (Git or SVN).');
    return;
  }

  const repo = await findRepo(cwd);
  if (!repo) {
    // Check if there's a stale KuzuDB index that needs migration
    const vcsRoot = getVCSRoot(cwd);
    const repoRoot = vcsRoot?.root ?? cwd;
    const { storagePath } = getStoragePaths(repoRoot);
    if (await hasKuzuIndex(storagePath)) {
      console.log('Repository has a stale KuzuDB index from a previous version.');
      console.log('Run: gitnexus analyze   (rebuilds the index with LadybugDB)');
    } else {
      console.log('Repository not indexed.');
      console.log('Run: gitnexus analyze');
    }
    return;
  }

  const currentRevision = vcsAdapter.getCurrentRevision();
  const vcsType = getVCSType(repo.meta);

  // Use lastRevision if available, otherwise fall back to lastCommit
  const lastRevision = repo.meta.lastRevision ?? repo.meta.lastCommit;

  const isUpToDate = currentRevision === lastRevision;

  console.log(`Repository: ${repo.repoPath}`);
  console.log(`VCS Type: ${vcsType}`);
  console.log(`Indexed: ${new Date(repo.meta.indexedAt).toLocaleString()}`);

  if (vcsType === 'svn') {
    console.log(`Indexed revision: r${lastRevision}`);
    console.log(`Current revision: r${currentRevision}`);
  } else {
    console.log(`Indexed commit: ${lastRevision?.slice(0, 7)}`);
    console.log(`Current commit: ${currentRevision?.slice(0, 7)}`);
  }

  console.log(`Status: ${isUpToDate ? '✅ up-to-date' : '⚠️ stale (re-run gitnexus analyze)'}`);
};
