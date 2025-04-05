import { $ } from "bun";

const szip = 'E:/Apps/7-Zip/7z.exe';

const {versionId} = await Bun.file('./src/modrinth.index.json').json();

const dest = `./out/ATFC 1.11 Remix ${versionId}.mrpack`;

await $`rm -f ${dest}`;
await $`${szip} a -tzip -mx9 ${dest} ./modrinth.index.json ./overrides`;

// bun add -D @types/bun
// bun build.mts