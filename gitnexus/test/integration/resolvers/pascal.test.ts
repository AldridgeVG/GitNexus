/**
 * Pascal: inherited call resolution + heritage extraction
 */
import { describe, it, expect, beforeAll } from 'vitest';
import path from 'path';
import {
  FIXTURES,
  getRelationships,
  getNodesByLabel,
  edgeSet,
  runPipelineFromRepo,
  type PipelineResult,
} from './helpers.js';
import { pascalProvider } from '../../../src/core/ingestion/languages/pascal.js';
import { loadParser, loadLanguage } from '../../../src/core/tree-sitter/parser-loader.js';
import { SupportedLanguages } from 'gitnexus-shared';

describe('Pascal inherited resolution', () => {
  let result: PipelineResult;

  beforeAll(async () => {
    result = await runPipelineFromRepo(path.join(FIXTURES, 'pascal-inherited'), () => {});
  }, 60000);

  it('provider labelOverride exists', () => {
    expect(pascalProvider.labelOverride).toBeDefined();
  });

  it('labelOverride returns Constructor for constructor defProc', async () => {
    const parser = await loadParser();
    await loadLanguage(SupportedLanguages.Pascal);
    const code = 'constructor TParent.Create;\nbegin\nend;\n';
    const tree = parser.parse(code);
    const defProc = tree.rootNode.namedChildren[0]; // defProc
    expect(defProc.type).toBe('defProc');
    const label = pascalProvider.labelOverride!(defProc, 'Function');
    expect(label).toBe('Constructor');
  });

  it('detects both classes', () => {
    expect(getNodesByLabel(result, 'Class')).toEqual(['TChild', 'TParent']);
  });

  it('emits EXTENDS edge: TChild → TParent', () => {
    const extends_ = getRelationships(result, 'EXTENDS');
    expect(extends_.length).toBe(1);
    expect(edgeSet(extends_)).toEqual(['TChild → TParent']);
  });

  it('emits CALLS edge from TChild.Create to TParent.Create via inherited', () => {
    const allNodes: { label: string; name: string; id: string }[] = [];
    result.graph.forEachNode((n) => {
      allNodes.push({ label: n.label, name: n.properties.name ?? n.id, id: n.id });
    });
    console.log(
      'ALL NODES:',
      allNodes.sort((a, b) => a.label.localeCompare(b.label) || a.name.localeCompare(b.name)),
    );
    const calls = getRelationships(result, 'CALLS');
    console.log(
      'ALL CALLS:',
      calls.map((c) => `${c.sourceLabel}:${c.source} -> ${c.targetLabel}:${c.target}`),
    );
    const inheritedCall = calls.find(
      (c) => c.source === 'TChild.Create' && c.target === 'TParent.Create',
    );
    expect(inheritedCall).toBeDefined();
  });
});
