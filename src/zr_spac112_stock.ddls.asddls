@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product stock'
define root view entity ZR_SPAC112_STOCK
  as select from zspac112_stock as stock
  association [0..1] to zspac112_product as _Product   // cardinality of [0..1] to allow empty cells
    on $projection.product_id = _Product.product_id
  association [0..1] to zspac112_whouse as _Warehouse
    on $projection.warehouse_id = _Warehouse.warehouse_id
{
  key stock.warehouse_id as warehouse_id,
  key stock.product_id   as product_id,
      stock.amount       as Amount,

      _Product.product_name        as product_name,
      _Product.product_description as product_description,
      _Warehouse.warehouse_name    as warehouse_name,
      _Warehouse.warehouse_address as warehouse_address,
      _Warehouse.warehouse_city    as warehouse_city,
      _Warehouse.warehouse_zipcode as warehouse_zipcode,

      _Product,
      _Warehouse
}
