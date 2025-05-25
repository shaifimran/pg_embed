# pg_embed: PostgreSQL Extension for HuggingFace Embeddings

`pg_embed` is a PostgreSQL extension written in PL/Python that enables you to generate and store text embeddings directly in your database using HuggingFace's Inference API. This extension is ideal for adding semantic search, similarity, and AI-powered features to your PostgreSQL-backed applications.

## Features

- Generate embeddings for any text column in your tables.
- Automatically adds an `embedding` column if it doesn't exist.
- Stores embeddings in-place for efficient querying.
- Uses HuggingFace's hosted models (API key required).

## Installation

### Prerequisites

- PostgreSQL 13+ with PL/Python3 (`plpython3u`) enabled.
- Python `requests` module installed in PostgreSQL's Python environment.
- HuggingFace Inference API key ([get one here](https://huggingface.co/settings/tokens)).

### Linux

1. **Copy the extension files:**

   In the project directory, run:
   ```sh
   make install
   ```
   This copies `pg_embed.control` and `pg_embed--1.0.sql` to your PostgreSQL extension directory (e.g., `/usr/share/postgresql/17/extension/`).

2. **Install Python dependencies:**

   Switch to the `postgres` user and install `requests`:
   ```sh
   sudo -i -u postgres
   pip install requests
   ```

### Windows

- Manually copy `pg_embed.control` and `pg_embed--1.0.sql` to your PostgreSQL extension directory.
- Find the Python environment used by PostgreSQL and install the `requests` module there.

## Usage

1. **Start the PostgreSQL shell:**
   ```sh
   psql
   ```

2. **Enable required extensions:**
   ```sql
   CREATE EXTENSION IF NOT EXISTS plpython3u;
   CREATE EXTENSION pg_embed;
   ```

3. **Create a table:**
   ```sql
   CREATE TABLE docs (
     id SERIAL PRIMARY KEY,
     content TEXT
     -- embedding FLOAT8[]  -- optional; will be added automatically if missing
   );
   ```

4. **Insert data:**
   ```sql
   INSERT INTO docs (content) VALUES
     ('Hello world'),
     ('PostgreSQL + Embeddings');
   ```

5. **Generate and store embeddings:**
   ```sql
   SELECT generate_and_store_embeddings('docs', 'content', '<your_api_key>');
   ```

6. **View results:**
   ```sql
   SELECT * FROM docs;
   ```

## Function Reference

### `generate_and_store_embeddings(tbl_name TEXT, txt_col TEXT, hf_api_key TEXT)`

- `tbl_name`: Name of your table (e.g., `'docs'`)
- `txt_col`: Name of the text column to embed (e.g., `'content'`)
- `hf_api_key`: Your HuggingFace Inference API key

The function will:
- Add an `embedding FLOAT8[]` column if missing.
- Generate embeddings for all rows where the text column is not null and `embedding` is null.
- Store the embeddings in the table.

## Use Cases

- **Semantic Search:** Store and compare embeddings for advanced search and ranking.
- **Recommendation Systems:** Find similar items or users based on text similarity.
- **AI-Powered Analytics:** Enable clustering, classification, or anomaly detection on text data.
- **Chatbots & Assistants:** Precompute embeddings for FAQ or knowledge base entries.

## Notes

- The extension requires outbound HTTPS access to HuggingFace's API.
- Your API key must have permission to use the Inference API.
- For large tables, consider batching or rate limits imposed by HuggingFace.

## License

MIT

---

**Author:** Muhammad Shaif Imran
