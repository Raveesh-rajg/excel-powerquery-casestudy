import sys
from pathlib import Path
from decimal import Decimal
import shutil
import pytest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from prepare_data import clean, parse_date, ROOT

@pytest.mark.parametrize('value',['2026-03-04','3/04/2026','04-Mar-26'])
def test_date_contract(value): assert parse_date(value)=='2026-03-04'

def test_sources_reconcile_and_lookup_is_unique():
    data=clean()
    assert data['audit']['footer_rows_removed']==12
    assert data['audit']['duplicate_product_keys_removed']==3
    assert len(data['products'])==40 and len(data['budget'])==24
    assert len({r['order_id'] for r in data['sales']})==len(data['sales'])
    assert sum(Decimal(str(r['amount'])) for r in data['sales'])==Decimal(str(data['audit']['revenue']))

def test_unknown_header_fails_before_combining(tmp_path):
    shutil.copytree(ROOT/'data',tmp_path/'data')
    p=next((tmp_path/'data/exports').glob('*.csv'))
    p.write_text(p.read_text().replace(p.read_text().split(',')[0],'Unexpected',1))
    with pytest.raises(ValueError, match='Unknown column'): clean(tmp_path/'data')

def test_bad_date_is_rejected():
    with pytest.raises(ValueError): parse_date('31/31/2026')
