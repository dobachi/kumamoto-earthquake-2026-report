--[[
evidence.lua — この報告書が宣言する三区分を、読者に見える形で分離する。

  事実   : 引用ブロック（`> 「原文」— [S-xx]`）        -> class="evidence"
  未照合 : そのうち ⚠️ を含むもの                      -> class="evidence unverified"
  推論   : **【推】** で始まる段落                      -> class="inference"

自作レンダラ（tools/render_report.py）が HTML で行っていた分離を、
pandoc の AST 上で行う。HTML だけでなく PDF / EPUB にも同じ区分が乗る。

**この区分は装飾ではない。** 読者が「出典が言っていること」と「筆者の読み」を
取り違えないための機構であり、落とすと文書の性格が変わる。
--]]

local INFERENCE_MARK = "【推】"
local UNVERIFIED_MARK = "⚠️"

-- Inline 列を平文にする（マーカー検出のためだけに使う）
local function to_text(inlines)
  return pandoc.utils.stringify(inlines)
end

-- 引用ブロック -> evidence / unverified
function BlockQuote(el)
  local text = to_text(el.content)
  local unverified = text:find(UNVERIFIED_MARK, 1, true) ~= nil
  local classes = unverified and { "evidence", "unverified" } or { "evidence" }
  local label = unverified and "未照合" or "出典"

  local tag = pandoc.Div(
    { pandoc.Plain({ pandoc.Str(label) }) },
    pandoc.Attr("", { "etag" })
  )
  return pandoc.Div({ tag, table.unpack(el.content) }, pandoc.Attr("", classes))
end

-- **【推】** で始まる段落 -> inference
function Para(el)
  local text = to_text(el.content)
  if text:sub(1, #INFERENCE_MARK) ~= INFERENCE_MARK then
    return nil
  end
  local tag = pandoc.Div(
    { pandoc.Plain({ pandoc.Str("推論") }) },
    pandoc.Attr("", { "etag" })
  )
  return pandoc.Div({ tag, el }, pandoc.Attr("", { "inference" }))
end
