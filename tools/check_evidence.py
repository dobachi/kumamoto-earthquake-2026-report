#!/usr/bin/env python3
"""三区分（事実/未照合/推論）が HTML に反映されているかを確認する。

Lua フィルタが黙って落ちても Quarto はビルドを成功させる。
**この文書の性格は三区分に依存している**ので、件数を突き合わせる。

終了コード: 0=一致 / 1=不一致 / 2=ファイルが無い
"""
import pathlib, re, sys
QMD = pathlib.Path("reports/kumamoto-2026/index.qmd")
HTML = pathlib.Path("docs/reports/kumamoto-2026/index.html")
if not (QMD.exists() and HTML.exists()):
    print("ビルドしてから実行する（make html）"); sys.exit(2)
q = QMD.read_text(encoding="utf-8"); h = HTML.read_text(encoding="utf-8")
src_inf = len(re.findall(r"^\*\*【推】\*\*", q, re.M))
out_inf = len(re.findall(r'class="inference"', h))
out_unv = len(re.findall(r"evidence unverified", h))
src_unv = sum(1 for m in re.finditer(r"(?m)^>.*⚠️", q))
# 相互参照: 本文の §x.y と [S-xx] が全部リンクになっているか
body = q.split("---", 2)[2]
src_sec = len(re.findall(r"§\d", body))
src_cit = len(re.findall(r"\[S-\d+\]", body))
out_sec = len(re.findall(r'class="secref"', h))
out_cit = len(re.findall(r'class="srcref"', h))
bad = 0
for name, s, o in [("推論", src_inf, out_inf), ("未照合", src_unv, out_unv),
                   ("節参照", src_sec, out_sec), ("出典参照", src_cit, out_cit)]:
    ok = s == o
    bad += 0 if ok else 1
    print(f"  {'OK' if ok else 'NG'}  {name:6} 原文 {s} / 出力 {o}")
print("\n保証しないこと")
print("  - 区分が正しく付いているかは見ない。件数が合うことしか見ていない")
print("  - 未照合の判定は ⚠️ の有無に依存する。印を付け忘れた引用は素通りする")
print("  - 相互参照は件数しか見ない。**リンク先が正しいかは見ていない**")
print(f"\n判定: {'NG' if bad else 'OK'}（{bad}件）")
sys.exit(1 if bad else 0)
