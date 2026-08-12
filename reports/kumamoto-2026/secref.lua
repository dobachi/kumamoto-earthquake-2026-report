--[[
secref.lua — 本文中の `§2.1` のような節参照を、その節へのリンクにする。

**原文の表記は変えない。** ソースには `§2.1` と書いたままで、
リンクは描画時に生成する。こうすると、素の Markdown として読んでも壊れず、
公開版と非公開の調査記録でソースを同一に保てる。

やること:
  1. 見出し（## 3.1 …）から「節番号 -> 見出しの識別子」の対応表を作る
  2. 本文の Str に含まれる `§3.1` を、その識別子へのリンクに置き換える

対応表に無い節番号はリンクにしない（壊れたリンクを作らない）。
最後に、解決できなかった参照を stderr に出す — **黙って落とさない**。
--]]

local sec_id = {}      -- "3.1" -> "識別子"
local unresolved = {}  -- 解決できなかった節番号

-- 見出しテキストの先頭にある番号を拾う。「3.1 震度分布 — …」「0. まず何が…」
local function leading_number(s)
  return s:match("^(%d+%.%d+)%s") or s:match("^(%d+)%.%s") or s:match("^(%d+)%s")
end

function Pandoc(doc)
  -- 1周目: 見出しを集める
  doc.blocks:walk({
    Header = function(h)
      local num = leading_number(pandoc.utils.stringify(h.content))
      if num and h.identifier ~= "" then
        sec_id[num] = h.identifier
      end
    end
  })

  -- 2周目: 本文の §参照 をリンクにする
  local function link_refs(el)
    local text = el.text
    if not text:find("§") then return nil end

    local out = {}
    local pos = 1
    while true do
      local s, e, num = text:find("§(%d+%.?%d*)", pos)
      if not s then break end
      num = num:gsub("%.$", "")                     -- 「§3.」→「3」
      if s > pos then
        table.insert(out, pandoc.Str(text:sub(pos, s - 1)))
      end
      local id = sec_id[num]
      if id then
        table.insert(out, pandoc.Link(
          { pandoc.Str("§" .. num) }, "#" .. id,
          "", pandoc.Attr("", { "secref" })))
      else
        unresolved[num] = true
        table.insert(out, pandoc.Str("§" .. num))   -- 解決できなければ素のまま
      end
      pos = e + 1
    end
    if pos == 1 then return nil end
    if pos <= #text then
      table.insert(out, pandoc.Str(text:sub(pos)))
    end
    return out
  end

  doc.blocks = doc.blocks:walk({ Str = link_refs })

  local left = {}
  for k in pairs(unresolved) do table.insert(left, k) end
  if #left > 0 then
    table.sort(left)
    io.stderr:write("secref.lua: 解決できなかった節参照 -> §"
      .. table.concat(left, " §") .. "\n")
  end
  return doc
end
