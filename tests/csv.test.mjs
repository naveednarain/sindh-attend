import test from 'node:test';
import assert from 'node:assert/strict';
import {csvCell,csvText} from '../src/lib/csv.mjs';
test('exports safely quote delimiters, quotes, and formula prefixes',()=>{
 assert.equal(csvCell('A "quoted", name'),'"A ""quoted"", name"');
 assert.equal(csvCell('=HYPERLINK("evil")'),'"\'=HYPERLINK(""evil"")"');
 assert.equal(csvCell('  +1'),'"\'  +1"');
 assert.equal(csvCell('\tformula'),'"\'\tformula"');
 assert.equal(csvText([['Course','Status'],['CS-305','present']]),'"Course","Status"\r\n"CS-305","present"');
});
