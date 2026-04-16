import { describe, it, expect, beforeAll } from 'vitest';
import path from 'path';
import { runPipelineFromRepo } from '../../src/core/ingestion/pipeline.js';
import type { PipelineResult } from '../../src/types/pipeline.js';

describe('Pascal 15_actual_code.pas pipeline', () => {
  let result: PipelineResult;

  beforeAll(async () => {
    result = await runPipelineFromRepo(
      path.resolve(__dirname, '..', '..', 'vendor', 'delphi-example', 'concrete'),
      () => {},
      { skipGraphPhases: true },
    );
  }, 60000);

  it('emits CALLS from HandleAppSysEvent to InsertEventInfo', () => {
    const calls = result.graph.relationships.filter((r) => r.type === 'CALLS');
    const relevant = calls.filter((r) => {
      const src = result.graph.getNode(r.sourceId);
      const tgt = result.graph.getNode(r.targetId);
      return (
        (src?.properties.name as string)?.includes('HandleAppSysEvent') &&
        (tgt?.properties.name as string)?.includes('InsertEventInfo')
      );
    });
    expect(relevant.length).toBeGreaterThan(0);
  });
});
