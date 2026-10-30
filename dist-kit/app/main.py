"""LGNS Claimer — 图形界面骨架（PySide6）。

只做只读 RPC 探活：不涉及钱包、私钥、签名、交易。
RPC 地址可在界面里改，默认值仅为占位。
"""

from __future__ import annotations

import json
import os
import sys
import urllib.request

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

APP_VERSION = "1.0.0"
DEFAULT_RPC = "https://rpc.anubispace.org"
EXPECTED_CHAIN_ID = 6714


def config_path() -> str:
    """配置放 exe 同目录；不可写时退回用户目录。"""
    base = (
        os.path.dirname(sys.executable)
        if getattr(sys, "frozen", False)
        else os.path.dirname(os.path.abspath(__file__))
    )
    return os.path.join(base, "claimer-config.json")


def load_rpc() -> str:
    try:
        with open(config_path(), encoding="utf-8") as fh:
            return json.load(fh).get("rpc", DEFAULT_RPC)
    except Exception:  # noqa: BLE001 - 配置缺失就用默认值
        return DEFAULT_RPC


def save_rpc(url: str) -> None:
    for path in (config_path(), os.path.join(os.path.expanduser("~"), ".lgns-claimer.json")):
        try:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump({"rpc": url}, fh, ensure_ascii=False, indent=2)
            return
        except Exception:  # noqa: BLE001 - 换下一个位置
            continue


def rpc_chain_id(url: str, timeout: int = 10) -> int:
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_chainId", "params": []}
    ).encode()
    req = urllib.request.Request(
        url, data=payload, headers={"content-type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = json.loads(resp.read().decode())
    return int(body["result"], 16)


class MainWindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle(f"LGNS Claimer v{APP_VERSION}")
        self.resize(560, 220)

        self.rpc_edit = QLineEdit(load_rpc())
        self.rpc_edit.setPlaceholderText("RPC 地址，例如 https://rpc.anubispace.org")

        self.status = QLabel("点「测试连接」读取链 ID（只读操作，不碰钱包）")
        self.status.setWordWrap(True)
        self.status.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)

        save_btn = QPushButton("保存地址")
        test_btn = QPushButton("测试连接")
        save_btn.clicked.connect(self.on_save)
        test_btn.clicked.connect(self.on_test)

        row = QHBoxLayout()
        row.addWidget(self.rpc_edit)
        row.addWidget(save_btn)
        row.addWidget(test_btn)

        layout = QVBoxLayout(self)
        layout.addWidget(QLabel(f"版本 v{APP_VERSION} · 仅供本人使用"))
        layout.addWidget(QLabel("RPC 地址："))
        layout.addLayout(row)
        layout.addWidget(self.status)

    def on_save(self) -> None:
        url = self.rpc_edit.text().strip()
        if not url.startswith(("http://", "https://")):
            self.status.setText("地址需要以 http:// 或 https:// 开头")
            return
        save_rpc(url)
        self.status.setText("已保存。下次启动自动读取。")

    def on_test(self) -> None:
        url = self.rpc_edit.text().strip()
        if not url:
            self.status.setText("先填一个 RPC 地址")
            return
        self.status.setText("连接中……")
        QApplication.processEvents()
        try:
            chain = rpc_chain_id(url)
        except Exception as exc:  # noqa: BLE001 - 界面上要看原因
            self.status.setText(f"连接失败：{exc}\n检查网络/代理，或换一个 RPC 地址。")
            return
        note = "（符合预期）" if chain == EXPECTED_CHAIN_ID else f"（预期 {EXPECTED_CHAIN_ID}，请核对）"
        self.status.setText(f"ChainID = {chain} {note}")


def main() -> int:
    app = QApplication([])
    win = MainWindow()
    win.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())