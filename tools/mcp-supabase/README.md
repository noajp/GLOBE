MCP Supabase Server (Node)

Overview
- Minimal Model Context Protocol server to access Supabase from MCP-compatible clients (Claude, Serena).
- Tools: select, insert, rpc.

Requirements
- Node.js 18+
- Env vars: SUPABASE_URL, SUPABASE_KEY (anon for normal use; service_role only for local/admin and with caution).

Install
1) cd tools/mcp-supabase
2) npm install

Run (standalone test)
3) node index.js  (will wait on stdio; best used via an MCP client)

Claude Desktop config (example)
~/.config/Claude/claude_desktop_config.json
{
  "mcpServers": {
    "supabase": {
      "command": "node",
      "args": ["/absolute/path/to/tools/mcp-supabase/index.js"],
      "env": {
        "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
        "SUPABASE_KEY": "YOUR_ANON_OR_SERVICE_KEY"
      }
    }
  }
}

Tools
- select: { table, columns?='*', filter? (eq only), limit?=100 }
- insert: { table, values }
- rpc: { name, params? }

Security Notes
- Prefer anon key + RLS. If you must use service_role, keep it local only and restrict exposed tools/tables.

