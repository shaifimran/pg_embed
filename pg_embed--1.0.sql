-- Ensure PL/Python is available
CREATE EXTENSION IF NOT EXISTS plpython3u;

-- Helper: fetch one embedding vector via the HF “router” endpoint
CREATE OR REPLACE FUNCTION get_embedding(
    input_text TEXT,
    hf_api_key TEXT
) RETURNS FLOAT8[] AS $$
import requests, plpy

API_URL = "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"
headers = {
    "Authorization": f"Bearer {hf_api_key}",
    "Content-Type": "application/json"
}

resp = requests.post(API_URL, headers=headers, json={"inputs": input_text})
if resp.status_code != 200:
    plpy.error(f"HuggingFace API error {resp.status_code}: {resp.text}")

data = resp.json()
if not isinstance(data, list) or len(data) == 0:
    plpy.error("Empty or invalid embedding response")

# Unwrap nested list if present
embedding = data[0] if isinstance(data[0], list) else data

if not all(isinstance(x, (int, float)) for x in embedding):
    plpy.error("Embedding contains non-numeric values")

return [float(x) for x in embedding]
$$ LANGUAGE plpython3u;


-- Main: generate + store embeddings for all rows missing them
CREATE OR REPLACE FUNCTION generate_and_store_embeddings(
    tbl_name TEXT,
    txt_col  TEXT,
    hf_api_key TEXT
) RETURNS VOID AS $$
import plpy

# Validate inputs
if not tbl_name or not txt_col:
    plpy.error("Both table name and text column must be provided")

# Check/add 'embedding' column
col_check_sql = """
    SELECT 1
      FROM information_schema.columns
     WHERE table_name = $1
       AND column_name = 'embedding'
"""
col_check_plan = plpy.prepare(col_check_sql, ["text"])
col_exists = plpy.execute(col_check_plan, [tbl_name])
if not col_exists:
    plpy.execute(f"ALTER TABLE {tbl_name} ADD COLUMN embedding FLOAT8[]")

# Fetch rows needing embeddings
select_sql = f"SELECT id, {txt_col} AS txt FROM {tbl_name} WHERE {txt_col} IS NOT NULL AND embedding IS NULL"
rows = plpy.execute(select_sql)

# Prepare plans
emb_plan    = plpy.prepare("SELECT get_embedding($1,$2) AS e", ["text","text"])
update_plan = plpy.prepare(f"UPDATE {tbl_name} SET embedding = $1 WHERE id = $2", ["float8[]","int"])

# Loop, fetch via helper, and store
for row in rows:
    try:
        emb_row = plpy.execute(emb_plan, [row["txt"], hf_api_key])
        emb = emb_row[0]["e"]
        plpy.execute(update_plan, [emb, row["id"]])
    except Exception as e:
        plpy.warning(f"row id={row['id']}: {e}")

$$ LANGUAGE plpython3u;
