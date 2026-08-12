--[[
srcref.lua — 本文の `[S-xx]` を、出典表の該当行へのリンクにする。

**原文の表記は変えない。** ソースは `[S-01]` のままで、リンクは描画時に作る。
素の Markdown として読んでも壊れず、公開版と非公開の調査記録でソースを一致させられる。

BibTeX（`@citekey`）に移せば同じことが標準機能で得られるが、この文書は
出典表に **Tier** と **照合状態（✅ / ⚠️）** を持っており、BibTeX はそれを表現しない。
**⚠️ 未照合の明示はこの文書の核心**なので、表記を維持したままリンクだけを足す。

やること:
  1. 出典表の1列目が `S-\d+` のセルに id を振る（src-S-01）
  2. 本文の `[S-01]` をその id へのリンクにする

表に無い出典を参照していたら stderr に出す。**黙って落とさない。**
（refs_integrity 検出器が同じことを終了コードで見ているが、描画時にも気づけるようにする）
--]]

local known = {}       -- "S-01" -> true
local missing = {}     -- 表に無いのに本文が参照している出典

-- 1周目: 出典表のセルに id を振る
local function tag_source_cells(tbl)
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      local first = row.cells[1]
      if first then
        local sid = pandoc.utils.stringify(first.contents):match("^%s*(S%-%d+)%s*$")
        if sid then
          known[sid] = true
          first.attr = pandoc.Attr("src-" .. sid, { "src-anchor" })
        end
      end
    end
  end
  return tbl
end

-- 2周目: 本文の [S-xx] をリンクにする
local function link_sources(el)
  local text = el.text
  if not text:find("%[S%-") then return nil end

  local out, pos = {}, 1
  while true do
    local s, e, sid = text:find("%[(S%-%d+)%]", pos)
    if not s then break end
    if s > pos then table.insert(out, pandoc.Str(text:sub(pos, s - 1))) end
    if known[sid] then
      table.insert(out, pandoc.Link(
        { pandoc.Str("[" .. sid .. "]") }, "#src-" .. sid,
        "", pandoc.Attr("", { "srcref" })))
    else
      missing[sid] = true
      table.insert(out, pandoc.Str("[" .. sid .. "]"))
    end
    pos = e + 1
  end
  if pos == 1 then return nil end
  if pos <= #text then table.insert(out, pandoc.Str(text:sub(pos))) end
  return out
end

function Pandoc(doc)
  doc.blocks = doc.blocks:walk({ Table = tag_source_cells })
  doc.blocks = doc.blocks:walk({ Str = link_sources })

  local left = {}
  for k in pairs(missing) do table.insert(left, k) end
  if #left > 0 then
    table.sort(left)
    io.stderr:write("srcref.lua: 出典表に無い参照 -> " .. table.concat(left, " ") .. "\n")
  end
  return doc
end
