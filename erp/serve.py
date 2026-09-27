"""正式執行：python -m erp.serve（預設 port 8100，和文件管理系統分開）。"""
import os

from waitress import serve

from . import create_app

if __name__ == '__main__':
    if not os.environ.get('ERP_SECRET_KEY'):
        raise SystemExit('請先設定環境變數 ERP_SECRET_KEY（長亂數），否則每次重啟所有人都會被登出')
    serve(create_app(), host=os.environ.get('ERP_HOST', '0.0.0.0'), port=int(os.environ.get('ERP_PORT', 8100)))
