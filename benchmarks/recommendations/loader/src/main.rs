//! One-shot loader for the recommendations demo/benchmark dataset: single
//! process, single Database handle, schema (indexes) applied before the
//! relationship-creation statements run -- the exported script's every
//! relationship statement does a `MATCH (x:Label{key: ...})` lookup, and
//! without a matching index that's a full label scan per lookup.
//! Lives in marsdb-demo (not the marsdb repo): it's benchmark tooling,
//! not a shipped example.
//!
//! Usage: load_recommendations <db-path> <schema-file> <data-file>
//! `schema-file` and `data-file` are plain, `;`-separated Cypher text.

use std::env;
use std::fs;
use std::time::Instant;

use marsdb::Database;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    let db_path = &args[1];
    let schema_path = &args[2];
    let data_path = &args[3];

    let _ = fs::remove_file(db_path);
    let db = Database::open(db_path)?;

    let t0 = Instant::now();
    let schema = fs::read_to_string(schema_path)?;
    db.execute_batch(&schema)?;
    println!("schema loaded in {:?}", t0.elapsed());

    let data = fs::read_to_string(data_path)?;
    let t1 = Instant::now();
    db.execute_batch(&data)?;
    println!("data loaded in {:?}", t1.elapsed());

    let nodes = db.execute("MATCH (n) RETURN count(n) AS c")?;
    let rels = db.execute("MATCH ()-[r]->() RETURN count(r) AS c")?;
    println!("nodes: {nodes:?}");
    println!("rels: {rels:?}");

    Ok(())
}
