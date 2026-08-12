.PHONY: html preview clean check
html:      ## サイト全体をビルド（docs/ へ出力）
	quarto render
preview:   ## ローカルプレビュー
	quarto preview
check:     ## 三区分が変換されているか確認
	@python3 tools/check_evidence.py
clean:
	rm -rf docs .quarto
