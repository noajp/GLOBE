import { createClient } from '@supabase/supabase-js'
import { z } from 'zod'
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'

// Environment
const { SUPABASE_URL, SUPABASE_KEY } = process.env
if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_KEY in environment')
}

const supabase = (SUPABASE_URL && SUPABASE_KEY)
  ? createClient(SUPABASE_URL, SUPABASE_KEY)
  : null

// Helpers
const ok = (data) => ({
  content: [{ type: 'text', text: JSON.stringify(data, null, 2) }]
})

const err = (message, details) => ({
  isError: true,
  content: [{ type: 'text', text: details ? `${message}: ${details}` : message }]
})

// Server
const server = new Server({
  name: 'mcp-supabase',
  version: '0.1.0'
}, {
  capabilities: { tools: {} }
})

// Tool: select
server.tool('select', {
  description: 'Select rows from a table. Supports simple equality filters.',
  inputSchema: z.object({
    table: z.string(),
    columns: z.string().optional().default('*'),
    // filter: { column: value, ... } (eq only)
    filter: z.record(z.any()).optional(),
    limit: z.number().int().positive().max(1000).optional().default(100)
  })
}, async ({ table, columns, filter, limit }) => {
  if (!supabase) return err('Supabase client not initialized')
  try {
    let query = supabase.from(table).select(columns).limit(limit)
    if (filter) {
      for (const [col, val] of Object.entries(filter)) {
        // eq only
        query = query.eq(col, val)
      }
    }
    const { data, error } = await query
    if (error) return err('Select failed', error.message)
    return ok(data)
  } catch (e) {
    return err('Select exception', e.message)
  }
})

// Tool: insert
server.tool('insert', {
  description: 'Insert a single row into a table.',
  inputSchema: z.object({
    table: z.string(),
    values: z.record(z.any())
  })
}, async ({ table, values }) => {
  if (!supabase) return err('Supabase client not initialized')
  try {
    const { data, error } = await supabase.from(table).insert(values).select('*')
    if (error) return err('Insert failed', error.message)
    return ok(data)
  } catch (e) {
    return err('Insert exception', e.message)
  }
})

// Tool: rpc
server.tool('rpc', {
  description: 'Call a Postgres function (RPC).',
  inputSchema: z.object({
    name: z.string(),
    params: z.record(z.any()).optional()
  })
}, async ({ name, params }) => {
  if (!supabase) return err('Supabase client not initialized')
  try {
    const { data, error } = await supabase.rpc(name, params ?? {})
    if (error) return err('RPC failed', error.message)
    return ok(data)
  } catch (e) {
    return err('RPC exception', e.message)
  }
})

// Optional: storage.upload (base64)
server.tool('storageUpload', {
  description: 'Upload base64 data to a storage bucket path. Returns public URL.',
  inputSchema: z.object({
    bucket: z.string(),
    path: z.string(),
    base64: z.string(),
    contentType: z.string().optional().default('application/octet-stream'),
    makePublic: z.boolean().optional().default(true)
  })
}, async ({ bucket, path, base64, contentType, makePublic }) => {
  if (!supabase) return err('Supabase client not initialized')
  try {
    const buf = Buffer.from(base64, 'base64')
    const { error: upErr } = await supabase.storage.from(bucket).upload(path, buf, {
      contentType,
      upsert: true
    })
    if (upErr) return err('Upload failed', upErr.message)
    let url = null
    if (makePublic) {
      url = supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl
    }
    return ok({ path, publicUrl: url })
  } catch (e) {
    return err('Upload exception', e.message)
  }
})

// Start
const transport = new StdioServerTransport()
await server.connect(transport)
console.error('[mcp-supabase] server running on stdio')

