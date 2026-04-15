import { describe, it, expect, beforeAll } from 'vitest';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadParser, loadLanguage } from '../../src/core/tree-sitter/parser-loader.js';
import { SupportedLanguages } from 'gitnexus-shared';
import { getProvider } from '../../src/core/ingestion/languages/index.js';
import Parser from 'tree-sitter';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const concreteDir = path.resolve(__dirname, '..', '..', 'vendor', 'delphi-example', 'concrete');

function readFixture(filename: string): string {
  return fs.readFileSync(path.join(concreteDir, filename), 'utf-8');
}

function parseAndQuery(parser: Parser, content: string, queryStr: string) {
  const tree = parser.parse(content);
  const lang = parser.getLanguage();
  const query = new Parser.Query(lang, queryStr);
  const matches = query.matches(tree.rootNode);
  return { tree, matches };
}

function extractDefinitions(matches: any[]) {
  const defs: { type: string; name: string }[] = [];
  for (const match of matches) {
    for (const capture of match.captures) {
      if (
        capture.name === 'name' &&
        match.captures.some((c: any) => c.name.startsWith('definition.'))
      ) {
        const defType = match.captures.find((c: any) => c.name.startsWith('definition.'))!.name;
        defs.push({ type: defType, name: capture.node.text });
      }
    }
  }
  return defs;
}

function extractCalls(matches: any[]) {
  const calls: { name: string }[] = [];
  for (const match of matches) {
    for (const capture of match.captures) {
      if (capture.name === 'call.name') {
        calls.push({ name: capture.node.text });
      }
    }
  }
  return calls;
}

function extractCallNodes(matches: any[]) {
  const calls: { type: string; name?: string }[] = [];
  for (const match of matches) {
    const callCapture = match.captures.find((c: any) => c.name === 'call');
    const nameCapture = match.captures.find((c: any) => c.name === 'call.name');
    if (callCapture) {
      calls.push({
        type: callCapture.node.type,
        name: nameCapture?.node.text,
      });
    }
  }
  return calls;
}

function extractImports(matches: any[]) {
  const imports: { source: string }[] = [];
  for (const match of matches) {
    for (const capture of match.captures) {
      if (capture.name === 'import.source') {
        imports.push({ source: capture.node.text });
      }
    }
  }
  return imports;
}

describe('Pascal/Delphi extraction', () => {
  let parser: Parser;

  beforeAll(async () => {
    parser = await loadParser();
    await loadLanguage(SupportedLanguages.Pascal);
  });

  describe('Unit structure (01_unit_structure.pas)', () => {
    it('should extract unit name and imports', () => {
      const content = readFixture('01_unit_structure.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const imports = extractImports(matches);

      // Should detect uses clause imports
      expect(imports.length).toBeGreaterThan(0);
      const sources = imports.map((i) => i.source);
      expect(sources).toContain('SysUtils');
      expect(sources).toContain('Classes');
    });
  });

  describe('Data types (02_data_types.pas)', () => {
    it('should extract enum definitions', () => {
      const content = readFixture('02_data_types.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const enumDefs = defs.filter((d) => d.type === 'definition.enum');
      expect(enumDefs.length).toBeGreaterThan(0);
      const names = enumDefs.map((d) => d.name);
      expect(names).toContain('TCmdResult');
      expect(names).toContain('TTransType');
    });

    it('should extract type aliases', () => {
      const content = readFixture('02_data_types.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const typeDefs = defs.filter((d) => d.type === 'definition.type');
      expect(typeDefs.length).toBeGreaterThan(0);
    });
  });

  describe('Interface types (03_interface_types.pas)', () => {
    it('should extract interface definitions', () => {
      const content = readFixture('03_interface_types.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const interfaceDefs = defs.filter((d) => d.type === 'definition.interface');
      expect(interfaceDefs.length).toBeGreaterThan(0);
      const names = interfaceDefs.map((d) => d.name);
      expect(names).toContain('ILogProcessor');
      expect(names).toContain('IExecutor');
    });
  });

  describe('Class basic (04_class_basic.pas)', () => {
    it('should extract class definitions', () => {
      const content = readFixture('04_class_basic.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const classDefs = defs.filter((d) => d.type === 'definition.class');
      expect(classDefs.length).toBeGreaterThan(0);
      const names = classDefs.map((d) => d.name);
      expect(names).toContain('TBaseEvent');
      expect(names).toContain('TBaseEntity');
    });

    it('should extract property definitions', () => {
      const content = readFixture('04_class_basic.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const propDefs = defs.filter((d) => d.type === 'definition.property');
      expect(propDefs.length).toBeGreaterThan(0);
    });

    it('should extract bare method calls without parentheses', () => {
      const content = readFixture('04_class_basic.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const calls = extractCallNodes(matches);

      expect(calls.some((c) => c.name === 'Run')).toBe(true);
    });
  });

  describe('Procedures and functions (06_procedures_functions.pas)', () => {
    it('should extract function definitions', () => {
      const content = readFixture('06_procedures_functions.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const funcDefs = defs.filter((d) => d.type === 'definition.function');
      expect(funcDefs.length).toBeGreaterThan(0);
      const names = funcDefs.map((d) => d.name);
      expect(names).toContain('LoadTimeZone');
      expect(names).toContain('GetUTC8DateTime');
    });

    it('should extract function calls', () => {
      const content = readFixture('06_procedures_functions.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const calls = extractCalls(matches);

      expect(calls.length).toBeGreaterThan(0);
    });
  });

  describe('Generic types (09_generic_types.pas)', () => {
    it('should extract generic class definitions', () => {
      const content = readFixture('09_generic_types.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const classDefs = defs.filter((d) => d.type === 'definition.class');
      expect(classDefs.length).toBeGreaterThan(0);
    });
  });

  describe('Database operations (13_database_operations.pas)', () => {
    it('should extract class with methods', () => {
      const content = readFixture('13_database_operations.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const defs = extractDefinitions(matches);

      const classDefs = defs.filter((d) => d.type === 'definition.class');
      expect(classDefs.length).toBeGreaterThan(0);
      const names = classDefs.map((d) => d.name);
      expect(names).toContain('TDBUtil');
      expect(names).toContain('TSQLBuilder');

      const funcDefs = defs.filter((d) => d.type === 'definition.function');
      expect(funcDefs.length).toBeGreaterThan(0);
    });

    it('should extract inherited calls', () => {
      const content = readFixture('13_database_operations.pas');
      const provider = getProvider(SupportedLanguages.Pascal);
      const { matches } = parseAndQuery(parser, content, provider.treeSitterQueries);
      const calls = extractCallNodes(matches);

      const inheritedCalls = calls.filter((c) => c.type === 'inherited');
      expect(inheritedCalls.length).toBeGreaterThanOrEqual(2);
      expect(inheritedCalls.some((c) => c.name === 'Create')).toBe(true);
      expect(inheritedCalls.some((c) => !c.name)).toBe(true);
    });
  });
});
