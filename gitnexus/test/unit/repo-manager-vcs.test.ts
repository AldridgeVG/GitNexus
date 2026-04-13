/**
 * Repository Manager VCS Schema Tests
 *
 * Tests for VCS-related schema changes in repo-manager.ts
 */

import { describe, it, expect } from 'vitest';
import {
  migrateRepoMeta,
  getEffectiveRevision,
  getVCSType,
  type RepoMeta,
} from '../../src/storage/repo-manager.js';

describe('RepoMeta Migration', () => {
  it('should migrate old meta without vcsType', () => {
    const oldMeta = {
      repoPath: '/path/to/repo',
      lastCommit: 'abc123',
      indexedAt: '2024-01-01T00:00:00Z',
    } as Partial<RepoMeta> & { lastCommit: string };

    const migrated = migrateRepoMeta(oldMeta);

    expect(migrated.vcsType).toBe('git'); // Default to git
    expect(migrated.lastRevision).toBe('abc123'); // Same as lastCommit
    expect(migrated.lastCommit).toBe('abc123'); // Preserved
  });

  it('should preserve existing vcsType', () => {
    const meta = {
      repoPath: '/path/to/repo',
      lastCommit: 'abc123',
      vcsType: 'svn' as const,
      indexedAt: '2024-01-01T00:00:00Z',
    };

    const migrated = migrateRepoMeta(meta);

    expect(migrated.vcsType).toBe('svn');
  });

  it('should preserve existing lastRevision', () => {
    const meta = {
      repoPath: '/path/to/repo',
      lastCommit: 'abc123',
      lastRevision: '456',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    const migrated = migrateRepoMeta(meta);

    expect(migrated.lastRevision).toBe('456');
    expect(migrated.lastCommit).toBe('abc123'); // Preserved
  });

  it('should handle SVN meta correctly', () => {
    const svnMeta = {
      repoPath: '/path/to/svn/repo',
      lastCommit: '789', // SVN revision stored in lastCommit (old format)
      vcsType: 'svn' as const,
      lastRevision: '789',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    const migrated = migrateRepoMeta(svnMeta);

    expect(migrated.vcsType).toBe('svn');
    expect(migrated.lastCommit).toBe('789');
    expect(migrated.lastRevision).toBe('789');
  });
});

describe('getEffectiveRevision', () => {
  it('should return lastRevision when available', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc123',
      lastRevision: 'def456',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(getEffectiveRevision(meta)).toBe('def456');
  });

  it('should fall back to lastCommit when lastRevision is missing', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc123',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(getEffectiveRevision(meta)).toBe('abc123');
  });

  it('should prefer lastRevision even if empty string', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc123',
      lastRevision: '',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    // Empty string is still a valid value
    expect(getEffectiveRevision(meta)).toBe('');
  });
});

describe('getVCSType', () => {
  it('should return vcsType when available', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc',
      vcsType: 'svn',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(getVCSType(meta)).toBe('svn');
  });

  it('should default to git when vcsType is missing', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(getVCSType(meta)).toBe('git');
  });

  it('should return none when explicitly set', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: '',
      vcsType: 'none',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(getVCSType(meta)).toBe('none');
  });
});

describe('RepoMeta Type Compatibility', () => {
  it('should accept old format (only lastCommit)', () => {
    const oldFormat: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc123',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    // Should compile and work
    expect(oldFormat.lastCommit).toBe('abc123');
  });

  it('should accept new format (with vcsType and lastRevision)', () => {
    const newFormat: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc123',
      vcsType: 'svn',
      lastRevision: '456',
      indexedAt: '2024-01-01T00:00:00Z',
    };

    expect(newFormat.vcsType).toBe('svn');
    expect(newFormat.lastRevision).toBe('456');
  });

  it('should work with stats', () => {
    const meta: RepoMeta = {
      repoPath: '/path',
      lastCommit: 'abc',
      vcsType: 'git',
      lastRevision: 'abc',
      indexedAt: '2024-01-01T00:00:00Z',
      stats: {
        files: 100,
        nodes: 500,
        edges: 1000,
        communities: 5,
        processes: 10,
        embeddings: 50,
      },
    };

    expect(meta.stats?.files).toBe(100);
    expect(meta.stats?.nodes).toBe(500);
  });
});
