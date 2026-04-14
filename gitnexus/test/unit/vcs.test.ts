/**
 * VCS Abstraction Layer Tests
 *
 * Tests for GitAdapter, SVNAdapter, and VCS factory functions.
 */

import { describe, it, expect, beforeAll, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, writeFileSync, mkdirSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { execSync } from 'child_process';
import { pathToFileURL } from 'url';

import { hasGitDir, hasSVNDir, detectVCSType } from '../../src/storage/vcs.js';
import { GitAdapter } from '../../src/storage/vcs-git.js';
import { SVNAdapter } from '../../src/storage/vcs-svn.js';
import { createVCSAdapter, getVCSRoot, hasVCSDir } from '../../src/storage/vcs-factory.js';

// Detect SVN availability synchronously at module load time so that conditional tests work
const svnAvailable = (() => {
  try {
    execSync('svn --version', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
})();

describe('VCS Detection', () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'gitnexus-vcs-test-'));
  });

  afterEach(() => {
    try {
      execSync(`rm -rf "${tempDir}"`, { stdio: 'ignore' });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('hasGitDir', () => {
    it('should return true for directory with .git', () => {
      mkdirSync(join(tempDir, '.git'));
      expect(hasGitDir(tempDir)).toBe(true);
    });

    it('should return false for directory without .git', () => {
      expect(hasGitDir(tempDir)).toBe(false);
    });

    it('should return true for git worktree with .git file', () => {
      writeFileSync(join(tempDir, '.git'), 'gitdir: /path/to/main/.git/worktrees/foo');
      expect(hasGitDir(tempDir)).toBe(true);
    });
  });

  describe('hasSVNDir', () => {
    it('should return true for directory with .svn', () => {
      mkdirSync(join(tempDir, '.svn'));
      expect(hasSVNDir(tempDir)).toBe(true);
    });

    it('should return false for directory without .svn', () => {
      expect(hasSVNDir(tempDir)).toBe(false);
    });
  });

  describe('detectVCSType', () => {
    it('should detect git', () => {
      mkdirSync(join(tempDir, '.git'));
      expect(detectVCSType(tempDir)).toBe('git');
    });

    it('should detect svn', () => {
      mkdirSync(join(tempDir, '.svn'));
      expect(detectVCSType(tempDir)).toBe('svn');
    });

    it('should return none for non-vcs directory', () => {
      expect(detectVCSType(tempDir)).toBe('none');
    });

    it('should prefer git over svn if both present', () => {
      mkdirSync(join(tempDir, '.git'));
      mkdirSync(join(tempDir, '.svn'));
      expect(detectVCSType(tempDir)).toBe('git');
    });
  });

  describe('hasVCSDir', () => {
    it('should return true for git repo', () => {
      mkdirSync(join(tempDir, '.git'));
      expect(hasVCSDir(tempDir)).toBe(true);
    });

    it('should return true for svn repo', () => {
      mkdirSync(join(tempDir, '.svn'));
      expect(hasVCSDir(tempDir)).toBe(true);
    });

    it('should return false for non-vcs directory', () => {
      expect(hasVCSDir(tempDir)).toBe(false);
    });
  });
});

describe('GitAdapter', () => {
  let tempDir: string;
  let adapter: GitAdapter | null;

  beforeAll(() => {
    // Check if git is available
    try {
      execSync('git --version', { stdio: 'ignore' });
    } catch {
      // Skip all tests if git is not available
      return;
    }
  });

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'gitnexus-git-test-'));
    execSync('git init', { cwd: tempDir, stdio: 'ignore' });
    execSync('git config user.email "test@test.com"', { cwd: tempDir, stdio: 'ignore' });
    execSync('git config user.name "Test"', { cwd: tempDir, stdio: 'ignore' });
    writeFileSync(join(tempDir, 'file.txt'), 'hello');
    execSync('git add .', { cwd: tempDir, stdio: 'ignore' });
    execSync('git commit -m "initial"', { cwd: tempDir, stdio: 'ignore' });
    adapter = createVCSAdapter(tempDir) as GitAdapter;
  });

  afterEach(() => {
    adapter = null;
    try {
      execSync(`rm -rf "${tempDir}"`, { stdio: 'ignore' });
    } catch {
      // Ignore cleanup errors
    }
  });

  it('should create GitAdapter for git repo', () => {
    expect(adapter).toBeInstanceOf(GitAdapter);
    expect(adapter?.type).toBe('git');
  });

  it('should validate git repo', () => {
    expect(adapter?.isValid()).toBe(true);
  });

  it('should get current revision (commit hash)', () => {
    const revision = adapter?.getCurrentRevision();
    expect(revision).toBeDefined();
    expect(revision?.length).toBeGreaterThan(10);
    expect(revision).toMatch(/^[a-f0-9]+$/);
  });

  it('should get current commit (same as revision for git)', () => {
    const commit = adapter?.getCurrentCommit();
    const revision = adapter?.getCurrentRevision();
    expect(commit).toBe(revision);
  });

  it('should detect revision reachability', () => {
    const currentRev = adapter?.getCurrentRevision() ?? '';

    // Current revision should be reachable from itself
    expect(adapter?.isRevisionReachable(currentRev, currentRev)).toBe(true);

    // Create a new commit
    writeFileSync(join(tempDir, 'file2.txt'), 'world');
    execSync('git add .', { cwd: tempDir, stdio: 'ignore' });
    execSync('git commit -m "second"', { cwd: tempDir, stdio: 'ignore' });

    const newRev = adapter?.getCurrentRevision() ?? '';

    // Old revision should be reachable from new
    expect(adapter?.isRevisionReachable(currentRev, newRev)).toBe(true);

    // New revision should NOT be reachable from old (it's the other direction)
    expect(adapter?.isRevisionReachable(newRev, currentRev)).toBe(false);
  });

  it('should get changed files', () => {
    const currentRev = adapter?.getCurrentRevision() ?? '';

    // Create a new file and commit
    writeFileSync(join(tempDir, 'newfile.txt'), 'content');
    execSync('git add .', { cwd: tempDir, stdio: 'ignore' });
    execSync('git commit -m "add file"', { cwd: tempDir, stdio: 'ignore' });

    const newRev = adapter?.getCurrentRevision() ?? '';

    const changedFiles = adapter?.getChangedFiles(currentRev, newRev);
    expect(changedFiles).toContain('newfile.txt');
  });

  it('should check staleness', () => {
    const currentRev = adapter?.getCurrentRevision() ?? '';

    // Should not be stale compared to itself
    const staleness = adapter?.checkStaleness(currentRev);
    expect(staleness?.isStale).toBe(false);
    expect(staleness?.commitsBehind).toBe(0);

    // Create a new commit
    writeFileSync(join(tempDir, 'another.txt'), 'test');
    execSync('git add .', { cwd: tempDir, stdio: 'ignore' });
    execSync('git commit -m "another"', { cwd: tempDir, stdio: 'ignore' });

    // Should be stale compared to old revision
    const newStaleness = adapter?.checkStaleness(currentRev);
    expect(newStaleness?.isStale).toBe(true);
    expect(newStaleness?.commitsBehind).toBe(1);
    expect(newStaleness?.hint).toContain('1 commit behind');
  });
});

describe('SVNAdapter', () => {
  let tempDir: string;
  let adapter: SVNAdapter | null;
  let repoDir: string;

  beforeEach(() => {
    if (!svnAvailable) {
      return;
    }
    tempDir = mkdtempSync(join(tmpdir(), 'gitnexus-svn-test-'));
    repoDir = join(tempDir, 'repo');
    const wcDir = join(tempDir, 'wc');

    // Create SVN repository
    mkdirSync(repoDir);
    execSync(`svnadmin create "${repoDir}"`, { stdio: 'ignore' });

    // Checkout working copy
    const repoUrl = pathToFileURL(repoDir).href;
    execSync(`svn checkout "${repoUrl}" "${wcDir}"`, { stdio: 'ignore' });

    // Create initial commit
    writeFileSync(join(wcDir, 'file.txt'), 'hello');
    execSync('svn add file.txt', { cwd: wcDir, stdio: 'ignore' });
    execSync('svn commit -m "initial"', { cwd: wcDir, stdio: 'ignore' });
    // Update working copy so that its BASE revision matches HEAD after commit
    execSync('svn update', { cwd: wcDir, stdio: 'ignore' });

    adapter = createVCSAdapter(wcDir) as SVNAdapter;
  });

  afterEach(() => {
    if (!svnAvailable) {
      return;
    }
    adapter = null;
    try {
      execSync(`rm -rf "${tempDir}"`, { stdio: 'ignore' });
    } catch {
      // Ignore cleanup errors
    }
  });

  const itIfSvn = svnAvailable ? it : it.skip;

  itIfSvn('should create SVNAdapter for svn repo', () => {
    expect(adapter).toBeInstanceOf(SVNAdapter);
    expect(adapter?.type).toBe('svn');
  });

  itIfSvn('should validate svn repo', () => {
    expect(adapter?.isValid()).toBe(true);
  });

  itIfSvn('should get current revision number', () => {
    const revision = adapter?.getCurrentRevision();
    expect(revision).toBeDefined();
    // Should be a numeric string
    expect(revision).toMatch(/^\d+$/);
    expect(parseInt(revision ?? '0', 10)).toBeGreaterThanOrEqual(1);
  });

  itIfSvn('should get current commit (same as revision for svn)', () => {
    const commit = adapter?.getCurrentCommit();
    const revision = adapter?.getCurrentRevision();
    expect(commit).toBe(revision);
  });

  itIfSvn('should detect revision reachability by comparing numbers', () => {
    const currentRev = adapter?.getCurrentRevision() ?? '1';

    // Same revision should be reachable
    expect(adapter?.isRevisionReachable(currentRev, currentRev)).toBe(true);

    // Lower revision should be reachable from higher
    expect(adapter?.isRevisionReachable('1', '2')).toBe(true);
    expect(adapter?.isRevisionReachable('1', '5')).toBe(true);

    // Higher revision should NOT be reachable from lower
    expect(adapter?.isRevisionReachable('5', '1')).toBe(false);
    expect(adapter?.isRevisionReachable('2', '1')).toBe(false);
  });

  itIfSvn('should handle invalid revision for reachability', () => {
    expect(adapter?.isRevisionReachable('abc', 'def')).toBe(false);
    expect(adapter?.isRevisionReachable('', '')).toBe(false);
  });

  itIfSvn('should check staleness', () => {
    const currentRev = adapter?.getCurrentRevision() ?? '1';

    // Should not be stale compared to itself
    const staleness = adapter?.checkStaleness(currentRev);
    expect(staleness?.isStale).toBe(false);
    expect(staleness?.commitsBehind).toBe(0);

    // Simulate older revision (should be stale)
    const oldRev = String(parseInt(currentRev, 10) - 1);
    const newStaleness = adapter?.checkStaleness(oldRev);
    expect(newStaleness?.isStale).toBe(true);
    expect(newStaleness?.commitsBehind).toBe(1);
    expect(newStaleness?.hint).toContain('1 revision behind');
  });
});

describe('VCS Factory', () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), 'gitnexus-factory-test-'));
  });

  afterEach(() => {
    try {
      execSync(`rm -rf "${tempDir}"`, { stdio: 'ignore' });
    } catch {
      // Ignore cleanup errors
    }
  });

  it('should return null for non-vcs directory', () => {
    expect(createVCSAdapter(tempDir)).toBeNull();
  });

  it('should create GitAdapter for git repo', () => {
    mkdirSync(join(tempDir, '.git'));
    const adapter = createVCSAdapter(tempDir);
    expect(adapter?.type).toBe('git');
  });

  it('should create SVNAdapter for svn repo', () => {
    mkdirSync(join(tempDir, '.svn'));
    const adapter = createVCSAdapter(tempDir);
    expect(adapter?.type).toBe('svn');
  });

  it('should prefer git over svn', () => {
    mkdirSync(join(tempDir, '.git'));
    mkdirSync(join(tempDir, '.svn'));
    const adapter = createVCSAdapter(tempDir);
    expect(adapter?.type).toBe('git');
  });

  describe('getVCSRoot', () => {
    it('should return null for non-vcs directory', () => {
      expect(getVCSRoot(tempDir)).toBeNull();
    });

    it('should find git root', () => {
      // Initialize a real git repo (not just create .git directory)
      execSync('git init', { cwd: tempDir, stdio: 'ignore' });
      const subDir = join(tempDir, 'subdir', 'nested');
      mkdirSync(subDir, { recursive: true });

      const result = getVCSRoot(subDir);
      expect(result?.type).toBe('git');
      expect(result?.root).toBe(tempDir);
    });
  });
});
