import { $ } from "bun";
import crypto from "node:crypto";
import fs from "node:fs/promises";

class BuildProcessor { 
    private modrinthIndex: any = {};
    private lastCommitSha = '';
    private excludeFiles: string[] = [];

    private log(message: string, color: string = 'white') {
        console.log(Bun.color(color, 'ansi') + message);
    }

    private async processFile(filename: string, ghFiles: GitHubFile[], folder: string): Promise<void> {
        if (this.modrinthIndex.files.some(file => file.path === `${folder}/${filename}`)) {
            this.log(`Skipping ${folder}/${filename}, already in modrinthIndex.files`, 'yellow');
            return;
        }

        const filePath = `./src/overrides/${folder}/${filename}`;
        const fileBuffer = await fs.readFile(filePath);

        const sha1 = crypto.createHash('sha1').update(fileBuffer).digest('hex');
        const sha512 = crypto.createHash('sha512').update(fileBuffer).digest('hex');

        const ghFile = ghFiles.find((file) => file.name === filename && file.size === fileBuffer.length && file.type === 'file');
        if (!ghFile) {
            this.log(`Skipping ${folder}/${filename}, not found in GitHub API response!`, 'red');
            return;
        }

        this.log(`Adding ${folder}/${filename} as GH download`, 'green');

        this.modrinthIndex.files.push({
            "downloads": [ghFile.download_url],
            "env": {
                "client": "required",
                "server": "required"
            },
            "fileSize": fileBuffer.length,
            "hashes": {
                "sha1": sha1,
                "sha512": sha512
            },
            "path": `${folder}/${filename}`,
        });
        this.excludeFiles.push(filename);
    }

    private async processFileGroup(folder: string): Promise<void> {
        const files = await fs.readdir(`./src/overrides/${folder}`);
        const ghResponse = await Bun.fetch(`https://api.github.com/repos/silentbox-stream/atfc-remix/contents/src/overrides/${folder}?ref=${this.lastCommitSha}`);
        const ghFiles = await ghResponse.json();
        for (const filename of files) {
            await this.processFile(filename, ghFiles, folder);
        }
    }

    private async createZipFile(versionId: string): Promise<void> {
        const szip = 'E:/Apps/7-Zip/7z.exe';
        const dest = `./out/ATFC 1.11 Remix ${versionId}.mrpack`;
        console.log(`Creating ${dest}...`);
        if (await fs.stat(dest).catch(() => false)) {
            await fs.unlink(dest);
        }
        console.log(Bun.color('gray', 'ansi'));
        await $`${szip} a -tzip -mx9 -xr!resourcepacks -xr!mods ${dest} ./src/modrinth.index.json ./src/overrides`;
    }

    public async run() {
        this.modrinthIndex = await Bun.file('./src/modrinth.index.json').json();
        this.lastCommitSha = (await $`git rev-parse HEAD`.text()).trim();

        await this.processFileGroup('resourcepacks');
        await this.processFileGroup('mods');

        await fs.writeFile('./src/modrinth.index.json', JSON.stringify(this.modrinthIndex, null, 4), 'utf-8');

        const { versionId } = await Bun.file('./src/modrinth.index.json').json();
        await this.createZipFile(versionId);
    }
}

interface GitHubFile {
    name: string;
    size: number;
    type: string;
    download_url: string;
}

const processor = new BuildProcessor();
await processor.run();
