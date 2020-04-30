const fs = require("fs");
const { initNiod, execute } = require("niod");

const dbModel = {
    blue_points: 1000,
    objective_zones: {
        "Capture-Zone": { alive: true },
    },
    sam_zones: {
        "SA-10-1": { alive: true },
        "SA-10-2": { alive: true },
        "SA-10-3": { alive: true },
        "SA-6-1": { alive: true },
        "SA-6-2": { alive: true },
        "SA-6-3": { alive: true },
    },
    iran_blocus: {
        "Iran Blocus 1": { alive: true },
        "Iran Blocus 2": { alive: true },
    },
    iran_ewr: {
        "Iran EWR 1": { alive: true },
        "Iran EWR 2": { alive: true }
    },
    cap_squadron_number: 10,
    gci_squadron_number: 10
}

const initDb = () => {
    try {
        return JSON.parse(fs.readFileSync("db.json"));
    } catch (err) {
        console.error("Error: Couldn't load db from db.json file, loading empty model instead", err)
        return dbModel;
    }
}

const saveDb = (db) => {
    fs.writeFileSync("db.json", JSON.stringify(db));
    console.log("Saved database file to db.json")
}

initNiod().then(() => {
    const db = initDb();
    execute(
        "setMissionDb",
        db,
        (result) => console.log("setMissionDb, server returned: ", result)
    );
    setInterval(
        () =>
            execute("getMissionDb", {}, db => {
                console.log("got mission db");
                saveDb(db);
            }
            )
        ,
        30000
    );
});