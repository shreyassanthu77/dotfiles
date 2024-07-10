const entry = App.configDir + "/src/config.ts";
const outdir = "/tmp/ags/js";

const username = Utils.exec("whoami").trim();
const home = `/home/${username}`;
const bun = `${home}/.local/bin/bun`;
try {
  Utils.exec([
    bun,
    "build",
    entry,
    "--outdir",
    outdir,
    "--external",
    "resource://*",
    "--external",
    "gi://*",
  ]);
  await import(`file://${outdir}/config.js`);
} catch (error) {
  console.error(error);
}

export {};
