---
title: Compass-2-1-建表(dim-dwd)
categories:
- 大数据火星人业务
---
```
----------------dim层----------------
CREATE DATABASE compass_dim LOCATION '/warehouse/compass/compass_dim.db';


-- ### 1.产品库存维度表(全量表)


DROP TABLE IF EXISTS compass_dim.dim_product_full;
CREATE EXTERNAL TABLE IF NOT EXISTS compass_dim.dim_product_full
(
    CINVCODE           string COMMENT 'sku code',
    CINVSTD            string COMMENT 'sku名称',
    cinvccode          string COMMENT '型号code',
    cinvcname          string COMMENT '型号名',
    cinvcname_real     string COMMENT '型号名(截取-)',
    group_code         string COMMENT '系列code',
    group_name         string COMMENT '系列名',
    division_code      string COMMENT '大类code',
    division_name      string COMMENT '大类名称',
    CINVDEFINE1        string COMMENT '',
    CINVDEFINE2        string COMMENT '渠道类型',
    min_date           string COMMENT '上市日期',
    nowstock           STRING COMMENT '当前库存',
    usestock           STRING COMMENT '使用库存',
    lockstock          STRING COMMENT '锁定库存',
    quantityflc        string COMMENT '物理可用数（非锁定数量）',
    quantityflinlock   string COMMENT '入库锁定数',
    quantityfloutlock  string COMMENT '出库锁定数',
    quantityfloverlock string COMMENT '超期锁定数',
    quantityflbacklock string COMMENT '返工锁定数',
    quantityflnoactive string COMMENT '不可用数量（不可用状态货位中的数）',
    undefined1         string COMMENT '正在入库的数量（不计入库存）'
) COMMENT '产品维度表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dim.db/dim_product'
    TBLPROPERTIES ('orc.compress' = 'snappy');


-- ### 2.库存维度表(拉链表)*
-- DROP TABLE IF EXISTS compass_dim.dim_product_stock_zip;
-- CREATE EXTERNAL TABLE compass_dim.dim_product_stock_zip
-- (
--     cinvcode   STRING COMMENT 'sku_id',
--     nowstock   STRING COMMENT '当前库存',
--     usestock   STRING COMMENT '使用库存',
--     lockstock  STRING COMMENT '锁定库存',
--     start_date STRING COMMENT '开始日期',
--     end_date   STRING COMMENT '结束日期'
-- ) COMMENT '库存维度表'
--     PARTITIONED BY (`dt` STRING)
--     ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
--     STORED AS PARQUET
--     LOCATION '/warehouse/compass/compass_dim.db/dim_product_stock_zip'
--     TBLPROPERTIES ("parquet.compression" = "lzo");


-- ### 2.门店维度表(全量表)*


-- DROP TABLE IF EXISTS compass_dim.dim_customer;
-- CREATE EXTERNAL TABLE IF NOT EXISTS compass_dim.dim_customer
-- (
--     CCUSCODE    string,
--     CDCNAME     string, --地区名称
--     CCUSDEFINE8 string, --区域
--     CCUSNAME    string, --门店
--     ccusaddress string,
--     ccusdefine1 string
-- ) COMMENT '门店维度表'
--     PARTITIONED BY (`ds` string)
--     ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
--     STORED AS parquet
--     LOCATION '/warehouse/compass/compass_dim.db/dim_customer'
--     TBLPROPERTIES ('parquet.compress' = 'lzo');


-- ### 3.渠道维度表(全量表)


-- DROP TABLE IF EXISTS compass_dim.dim_customer;
-- CREATE EXTERNAL TABLE IF NOT EXISTS compass_dim.dim_customer
-- (
--
-- ) COMMENT '渠道维度表'
--     PARTITIONED BY (`ds` string)
--     ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
--     STORED AS parquet
--     LOCATION '/warehouse/compass/compass_dim.db/dim_customer'
--     TBLPROPERTIES ('parquet.compress' = 'lzo');


-- ### 4.地区维度表(特殊表)

DROP TABLE IF EXISTS compass_dim.dim_area_spec;
CREATE EXTERNAL TABLE compass_dim.dim_area_spec
(
    `code`        STRING COMMENT '编号',
    `name`        STRING COMMENT '名称',
    `parent_code` STRING COMMENT '父级',
    `short_name`  STRING COMMENT '简称',
    `longitude`   STRING COMMENT '经度',
    `latitude`    STRING COMMENT '纬度',
    `level`       STRING COMMENT '等级',
    `sort`        STRING COMMENT '排序'
) COMMENT '地区维度表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
    LOCATION '/warehouse/compass/compass_dim.db/dim_area_spec';


-- ### 5.时间维度表(特殊表)
CREATE TABLE compass_dim.dim_date_tmp
(
    `date_id` STRING COMMENT '日期'
) COMMENT '时间维度临时表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
    LOCATION '/warehouse/compass/compass_dim.db/dim_date_tmp';

DROP TABLE IF EXISTS compass_dim.dim_date_spec;
CREATE EXTERNAL TABLE compass_dim.dim_date_spec
(
    `date_id`     STRING COMMENT '日期',     -- date
    `week_id`     STRING COMMENT '周ID',    -- weekofyear(date_id)
    `week_day`    STRING COMMENT '周几',     -- if((dayofweek(date_id) - 1) = 0, 7, dayofweek(date_id) - 1)
    `day`         STRING COMMENT '每月的第几天', -- substr(date_id,9,2)
    `month`       STRING COMMENT '第几月',    -- month(date_id)
    `quarter`     STRING COMMENT '第几季度',   -- floor(substr(date_id,6,2)/3.1)+1
    `year`        STRING COMMENT '年',      -- year(date_id)
    `is_weekend`  STRING COMMENT '是否是周日',  -- if(date_sub(next_day(date_id,'MO'),1)=date_id,1,0)
    `is_monthend` STRING COMMENT '是否是月末',  -- if(add_months(date_sub(date_id,dayofmonth(date_id)),1)=date_id,1,0)
    `is_workday`  STRING COMMENT '是否是工作日',
    `holiday_id`  STRING COMMENT '节假日'
) COMMENT '时间维度表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dim.db/dim_date_spec'
    TBLPROPERTIES ("orc.compress" = "snappy");

INSERT OVERWRITE TABLE compass_dim.dim_date_spec
SELECT date_id,
       weekofyear(date_id),
       if((dayofweek(date_id) - 1) = 0, 7, dayofweek(date_id) - 1),
       substr(date_id, 9, 2),
       month(date_id),
       floor(substr(date_id, 6, 2) / 3.1) + 1,
       year(date_id),
       if(date_sub(next_day(date_id, 'MO'), 1) = date_id, 1, 0),
       if(add_months(date_sub(date_id, dayofmonth(date_id)), 1) = date_id, 1, 0),
       null,
       null
FROM compass_dim.dim_date_tmp;

select *
from compass_dim.dim_date_spec;


----------------dwd层----------------
CREATE DATABASE compass_dwd LOCATION '/warehouse/compass/compass_dwd.db';

-- -- ### 1.电商订单中间表
DROP TABLE IF EXISTS compass_dwd.dwd_edb_order_tmp;
CREATE EXTERNAL TABLE compass_dwd.dwd_edb_order_tmp
(
    order_totalfee               string COMMENT '订单总金额',
    exception                    string,
    payment_received_time        string COMMENT '到款时间',
    is_except                    string,
    sorting_code                 string COMMENT '分拣代码',
    buyer_name                   string COMMENT '买家姓名',
    discount                     string COMMENT '折扣',
    flag_color                   string COMMENT '旗帜颜色',
    express_no                   string COMMENT '快递单号',
    type                         string COMMENT '订单类型',
    net_weight_freight           string COMMENT '净重运费',
    file_operator                string COMMENT '归档员',
    out_tid                      string COMMENT '外部平台单号',
    province                     string COMMENT '省',
    cod_settlement_vouchernumber string COMMENT '货到付款结算凭证号',
    good_receive_time            string COMMENT '到货日期',
    weigh_operator               string COMMENT '称重员',
    book_delivery_time           string COMMENT '预计发货时间',
    real_pay_freight             string COMMENT '实付运费',
    three_codes                  string COMMENT '三段码',
    express_coding               string COMMENT 'EDB快递代码',
    is_print                     string COMMENT '是否打印,0或空表示未打印,1表示已打印',
    sku                          string COMMENT '产品条形码',
    cod_fee                      string COMMENT '货到付款金额',
    transaction_id               string COMMENT '交易编号',
    cancel_time                  string COMMENT '取消时间',
    buyer_message                string COMMENT '买家留言',
    destcode                     string,
    printer                      string COMMENT '打印员',
    product_num                  string COMMENT '产品数量',
    packager                     string COMMENT '打包员',
    pro_totalfee                 string COMMENT '产品总金额',
    is_pre_delivery_notice       string COMMENT '是否送货前通知',
    sending_type                 string COMMENT '配送方式',
    phone                        string COMMENT '电话',
    distributor_id               string COMMENT '分销商编号',
    promotion_info               string,
    alipay_id                    string COMMENT '支付宝账户',
    distributer                  string COMMENT '配货员',
    file_time                    string COMMENT '归档时间',
    point_pay                    string COMMENT '是否积分换购',
    distributor_mark             string COMMENT '分销商便签',
    status                       string COMMENT '处理状态',
    gross_weight_freight         string COMMENT '毛重运费',
    review_orders_operator       string COMMENT '审单员',
    city                         string COMMENT '市',
    delivery_name                string COMMENT '第三方快递名称',
    related_orders_type          string COMMENT '相关订单类型',
    city_code                    string COMMENT '市编码',
    inspect_time                 string COMMENT '验货时间',
    order_process_time           string COMMENT '处理订单需要的时间戳',
    distribut_time               string COMMENT '配货时间',
    is_cod                       string COMMENT '是否货到付款',
    modity_time                  string COMMENT '订单修改时间',
    discount_fee                 string COMMENT '优惠金额',
    message_time                 string COMMENT '短信发送时间',
    invoice_content              string COMMENT '开票内容',
    receiver_name                string COMMENT '收货人',
    print_time                   string COMMENT '打印时间',
    taobao_delivery_order_status string COMMENT '淘宝快递订单状态',
    currency                     string COMMENT '币种',
    system_remarks               string COMMENT '系统备注',
    order_channel                string COMMENT '订单渠道',
    tid_net_weight               string COMMENT '订单净重',
    superior_point               string COMMENT '上级积分',
    email                        string COMMENT '电子邮件',
    invoice_situation            string COMMENT '开票情况',
    pack_time                    string COMMENT '打包时间',
    cancel_operator              string COMMENT '取消员',
    address                      string COMMENT '地址',
    deliver_centre               string COMMENT '配送中心名称',
    enable_inte_sto_time         string COMMENT '启用智能仓库时间',
    taobao_delivery_status       string COMMENT '淘宝快递状态',
    abnormal_status              string COMMENT '异常状态',
    pay_mothed                   string COMMENT '支付方式',
    receiver_mobile              string COMMENT '收货手机',
    item_num                     string COMMENT '单品条数',
    service_remarks              string COMMENT '客服备注',
    express_col_fee              string COMMENT '快递代收金额',
    single_num                   string COMMENT '单品数量',
    is_flag                      string COMMENT '是否插旗',
    customer_id                  string COMMENT '客户编号',
    platform_status              string COMMENT '外部平台状态',
    updatetime                   string,
    is_inspection                string COMMENT '是否验货',
    delivery_status              string COMMENT '发货状态',
    plat_send_status             string COMMENT '平台发货状态',
    ts                           string,
    provinc_code                 string COMMENT '省编码',
    other_remarks                string COMMENT '其他备注',
    enable_inte_delivery_time    string COMMENT '启用智能快递时间',
    adv_distributer              string COMMENT '预配货员',
    breaker                      string COMMENT '中断员',
    cod_service_fee              string COMMENT '货到付款服务费',
    delivery_operator            string COMMENT '发货员',
    out_promotion_detail         string COMMENT '外部平台促销详情',
    express                      string COMMENT '快递公司',
    delivery_time                string COMMENT '发货时间',
    buyer_id                     string COMMENT '买家ID',
    tid                          string COMMENT '订单编号',
    invoice_name                 string COMMENT '发票名称',
    locker                       string COMMENT '锁定员',
    last_refund_time             string COMMENT '最后一次退款时间',
    dt                           string,
    express_code                 string COMMENT 'EDB快递编号(ID)',
    post                         string COMMENT '邮编',
    finance_review_operator      string COMMENT '财务审核人',
    order_creater                string COMMENT '下单员',
    total_num                    string,
    cost_point                   string COMMENT '消耗积分',
    origincode                   string,
    adv_distribut_time           string COMMENT '预配货时间',
    gross_weight                 string COMMENT '毛重',
    commission_fee               string COMMENT '佣金',
    big_marker                   string,
    resultnum                    string,
    taobao_delivery_method       string COMMENT '淘宝快递方式',
    area_code                    string COMMENT '区编码',
    alipay_status                string COMMENT '支付宝状态',
    receive_time                 string COMMENT '生成应收时间',
    deliver_station              string COMMENT '配送站点名称',
    shop_name                    string COMMENT '店铺名称',
    import_mark                  string COMMENT '导入标记:不导入,未导入,已处理,已导入,已取消',
    revoke_cancel_er             string COMMENT '反取消员',
    is_stock                     string COMMENT '是否缺货',
    advance_printer              string COMMENT '预打印员',
    finish_time                  string COMMENT '完成时间',
    order_disfee                 string COMMENT '整单优惠',
    pay_time                     string COMMENT '付款时间',
    review_orders_time           string COMMENT '审单时间',
    platform_preferential        string COMMENT '平台承担优惠合计',
    business_man                 string COMMENT '业务员',
    promotion_plan               string COMMENT '满足的促销方案',
    external_point               string COMMENT '外部积分',
    payment_received_operator    string COMMENT '到款员',
    district                     string COMMENT '区',
    merchant_disfee              string COMMENT '商家优惠金额',
    weigh_time                   string COMMENT '称重时间',
    shopid                       string COMMENT '店铺代码',
    last_returned_time           string COMMENT '最后一次退货时间',
    break_time                   string COMMENT '中断时间',
    inner_lable                  string COMMENT '内部便签',
    break_explain                string COMMENT '中断说明',
    plat_type                    string COMMENT '平台类型',
    invoice_title                string COMMENT '发票抬头',
    get_time                     string COMMENT '获取时间',
    channel_disfee               string COMMENT '渠道优惠金额',
    revoke_cancel_time           string COMMENT '反取消时间',
    online_express               string COMMENT '线上快递公司',
    point                        string COMMENT '获得积分',
    total_weight                 string COMMENT '总重量',
    royalty_fee                  string COMMENT '提成金额',
    maxrowver                    string,
    pay_status                   string COMMENT '付款状态',
    is_break                     string COMMENT '是否中断',
    real_income_freight          string COMMENT '实收运费',
    rate                         string COMMENT '汇率',
    storage_id                   string COMMENT '仓库编号',
    distributor_level            string COMMENT '分销商等级',
    invoice_fee                  string COMMENT '发票金额',
    freight_explain              string COMMENT '运费说明',
    invoice_type                 string COMMENT '发票类型',
    finance_review_time          string COMMENT '财务审核时间',
    inspecter                    string COMMENT '验货员',
    reference_price_paid         string COMMENT '实收参考价',
    other_fee                    string COMMENT '其他费用',
    related_orders               string COMMENT '相关订单',
    out_pay_tid                  string COMMENT '外部平台付款单号',
    refund_totalfee              string COMMENT '退款总金额',
    is_bill                      string COMMENT '是否开发票',
    is_new_customer              string COMMENT '是否新客户',
    message                      string COMMENT '短信通知',
    serial_num                   string COMMENT '流水号',
    jd_delivery_time             string COMMENT '送货时间',
    lock_time                    string COMMENT '锁定时间',
    tid_time                     string COMMENT '订货时间',
    order_from                   string COMMENT '订单来源',
    is_adv_sale                  string COMMENT '是否预售',
    merge_status                 string COMMENT '合并状态',
    is_promotion                 string COMMENT '促销标记',
    voucher_id                   string COMMENT '凭证单号',
    book_file_time               string COMMENT '预计归档时间',
    distributing_centre_name     string COMMENT '集散地名称',
    send_site_name               string COMMENT '发件网点名称',
    verificaty_time              string COMMENT '核销日期',
    tid_item                     string COMMENT '子订单JSONArray'
--     item_original_price          string COMMENT '原始价格',
--     item_item_discountfee        string COMMENT '单品优惠金额',
--     item_sell_price              string COMMENT '销售单价',
--     item_discount_amount         string COMMENT '打折金额',
--     item_timeinventory           string COMMENT '当期库存',
--     item_tid                     string COMMENT '订单编号',
--     item_send_num                string COMMENT '发货数量',
--     item_ferght                  string COMMENT '运费',
--     item_second_barcode          string COMMENT '备用条码',
--     item_out_tid                 string COMMENT '外部平台单号',
--     item_inspection_num          string COMMENT '验货数量',
--     item_barcode                 string COMMENT '条形码',
--     item_stock_situation         string COMMENT '产品缺货情况',
--     item_proexplain              string COMMENT '产品简介',
--     item_book_inventory          string COMMENT '台账库存',
--     item_credit_amount           string COMMENT '抵扣分摊金额',
--     item_weight                  string COMMENT '重量',
--     item_seller_remark           string COMMENT '卖家备注',
--     item_brand_name              string COMMENT '品牌名称',
--     item_plat_discount           string COMMENT '平台承担优惠分摊',
--     item_sncode                  string COMMENT '多个SN码中间以,隔开',
--     item_out_proid               string COMMENT '外部平台产品id',
--     item_refund_num              string COMMENT '退货数量',
--     item_promotion_info          string,
--     item_shopid                  string COMMENT '店铺编号',
--     item_product_specification   string COMMENT '产品规格',
--     item_distributer             string COMMENT '配货员',
--     item_iscombination           string COMMENT '是否组合(1是套装;0是本来就单品，2是包含在套装里的单品)',
--     item_pro_name                string COMMENT '网店产品名称',
--     item_sys_price               string COMMENT '软件销售单价',
--     item_pro_detail_code         string COMMENT '产品明细编号',
--     item_distribut_time          string COMMENT '配货时间',
--     item_refund_renum            string COMMENT '退货到货数量',
--     item_isgifts                 string COMMENT '是否赠品',
--     item_out_prosku              string COMMENT '外部平台产品sku_id',
--     item_gift_num                string COMMENT '赠品数量',
--     item_brand_number            string COMMENT '品牌编号',
--     item_storage_id              string COMMENT '仓库编号',
--     item_combine_barcode         string COMMENT '套装条形码',
--     item_buyer_memo              string COMMENT '买家留言',
--     item_store_location          string COMMENT '只返回一个库位，如果一个产品分配到多个库位，输出的是分配数量最多的库位',
--     item_cost_price              string COMMENT '成本价',
--     item_isbook_pro              string COMMENT '是否预售产品',
--     item_inspection_time         string COMMENT '验货日期',
--     item_md5_encryption          string COMMENT 'MD5加密值',
--     item_iscancel                string COMMENT '是否取消',
--     item_average_price           string COMMENT '加权平均单价',
--     item_pro_type                string COMMENT '产品状态',
--     item_specification           string COMMENT '规格',
--     item_product_no              string COMMENT '产品编号',
--     item_isscheduled             string COMMENT '是否预定',
--     item_book_storage            string COMMENT '预分配库存',
--     item_pro_num                 string COMMENT '订货数量',
--     item_sub_tid                 string COMMENT '子订单编号'
) COMMENT '电商订单临时表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_edb_order_tmp'
    TBLPROPERTIES ('orc.compress' = 'snappy');

-- ## 2.电商订单信息表
DROP TABLE IF EXISTS compass_dwd.dwd_edb_order_info;
CREATE EXTERNAL TABLE IF NOT EXISTS compass_dwd.dwd_edb_order_info
(
    tid                          string COMMENT '订单编号',
    customer_id                  string COMMENT '客户编号',
    distributor_id               string COMMENT '分销商编号',
    shop_name                    string COMMENT '店铺名称',
    shopid                       string COMMENT '店铺编号',
    order_channel                string COMMENT '订单渠道',
    buyer_id                     string COMMENT '买家ID',
    buyer_name                   string COMMENT '买家姓名',
    type                         string COMMENT '订单类型',
    status                       string COMMENT '处理状态(未确认/已确认/已作废)',
    abnormal_status              string COMMENT '异常状态',
    merge_status                 string COMMENT '合并状态',
    receiver_name                string COMMENT '收货人',
    receiver_mobile              string COMMENT '收货手机',
    phone                        string COMMENT '电话',
    provinc_code                 string COMMENT '省编码',
    city_code                    string COMMENT '市编码',
    area_code                    string COMMENT '区编码',
    province                     string COMMENT '省',
    city                         string COMMENT '市',
    district                     string COMMENT '区',
    address                      string COMMENT '地址',
    is_bill                      string COMMENT '是否开发票',
    pro_totalfee                 string COMMENT '产品总金额',
    order_totalfee               string COMMENT '订单总金额',
    reference_price_paid         string COMMENT '实收参考价',
    cod_fee                      string COMMENT '货到付款金额',
    other_fee                    string COMMENT '其他费用',
    refund_totalfee              string COMMENT '退款总金额',
    discount_fee                 string COMMENT '优惠金额',
    platform_preferential        string COMMENT '平台承担优惠合计',
    is_cod                       string COMMENT '是否货到付款',
    express_no                   string COMMENT '快递单号',
    express                      string COMMENT '快递公司',
    express_coding               string COMMENT 'EDB快递代码',
    real_income_freight          string COMMENT '实收运费',
    tid_time                     string COMMENT '订货时间',
    pay_time                     string COMMENT '付款时间',
    get_time                     string COMMENT '获取时间',
    file_time                    string COMMENT '归档时间',
    finish_time                  string COMMENT '完成时间',
    modity_time                  string COMMENT '订单修改时间',
    delivery_status              string COMMENT '发货状态',
    buyer_message                string COMMENT '买家留言',
    service_remarks              string COMMENT '客服备注',
    other_remarks                string COMMENT '其他备注',
    is_stock                     string COMMENT '是否缺货',
    import_mark                  string COMMENT '导入标记:不导入,未导入,已处理,已导入,已取消',
    product_num                  string COMMENT '产品数量',
    item_num                     string COMMENT '单品条数',
    single_num                   string COMMENT '单品数量',
    pay_status                   string COMMENT '支付状态',
    platform_status              string COMMENT '外部订单状态:待退款部分退款/待退款全部退款/等待买家付款/货到付款/交易成功/交易关闭/买家已付款/缺货订单未付款/已发货/已付款/已签收/交易成功/已取消/预退款',
    taobao_delivery_order_status string COMMENT '淘宝快递订单状态:待退货部分退货/待退货全部退货/待退货所有/退货到货部分退货/退货到货全部退货/退货到货所有/未发货/已发货',
    plat_send_status             string COMMENT '平台发货状态',
    plat_type                    string COMMENT '平台类型',
    is_adv_sale                  string COMMENT '是否预售'
) COMMENT '电商订单信息表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_edb_order_info'
    TBLPROPERTIES ('orc.compress' = 'snappy');

show create table compass_dwd.dwd_edb_order_detail;

-- ## 3.电商订单详情表
DROP TABLE IF EXISTS compass_dwd.dwd_edb_order_detail;
CREATE EXTERNAL TABLE IF NOT EXISTS compass_dwd.dwd_edb_order_detail
(
    `sub_tid`        STRING COMMENT '子订单号',                      -- sub_tid,,autoid,
    `tid`            STRING COMMENT '订单号',                       -- tid,dingdanbianhao,dlid
    `buyer_id`       STRING COMMENT '用户id',                      -- buyer_id，
    `buyer_name`     STRING COMMENT '用户id',                      -- buyer_id，
    `provinc_code`   string COMMENT '省编码',
    `city_code`      string COMMENT '市编码',
    `area_code`      string COMMENT '区编码',
    `province`       string COMMENT '省',
    `city`           string COMMENT '市',
    `district`       string COMMENT '区',
    `customer_id`    STRING COMMENT '门店ID',                      -- customer_id，
    `order_channel`  STRING COMMENT '订单渠道',
    `shop_name`      STRING COMMENT '店铺名称',
    `shopid`         STRING COMMENT '店铺编号',
    `sku_id`         STRING COMMENT 'sku商品id',                   -- product_no，
    `sku_name`       STRING COMMENT 'sku名称',                     -- product_specification，
    `pro_name`       STRING COMMENT '产品类型(原始产品/促销赠品/更换产品/手动添加)', -- pro_type
    `pro_type`       STRING COMMENT '产品类型(原始产品/促销赠品/更换产品/手动添加)', -- pro_type
    `tid_time`       STRING COMMENT '创建时间',                      -- tid_time
    `pro_num`        BIGINT COMMENT '商品数量',                      -- pro_num
    `original_price` DECIMAL(16, 2) COMMENT '原始单价',              -- ，item_original_price
    `sell_price`     DECIMAL(16, 2) COMMENT '最终单价'               -- item_sell_price
) COMMENT '电商订单详情表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_edb_order_detail'
    TBLPROPERTIES ('orc.compress' = 'snappy');

-- ## 4.电商支付表(事务型事实表)

DROP TABLE IF EXISTS compass_dwd.dwd_edb_order_payment;
CREATE EXTERNAL TABLE compass_dwd.dwd_edb_order_payment
(
    `tid`            STRING COMMENT '订单编号',
    `out_tid`        STRING COMMENT '外部平台单号',
    `out_pay_tid`    STRING COMMENT '外部平台付款单号',
    `buyer_id`       STRING COMMENT '用户id',
    `buyer_name`     STRING COMMENT '用户id',
    `provinc_code`   string COMMENT '省编码',
    `city_code`      string COMMENT '市编码',
    `area_code`      string COMMENT '区编码',
    `province`       string COMMENT '省',
    `city`           string COMMENT '市',
    `district`       string COMMENT '区',
    `customer_id`    STRING COMMENT '门店ID',
    `shop_name`      STRING COMMENT '店铺名称',
    `shopid`         STRING COMMENT '店铺编号',
    `pay_mothed`     STRING COMMENT '支付类型',
    `order_totalfee` DECIMAL(16, 2) COMMENT '支付金额',
    `pay_status`     STRING COMMENT '支付状态',
    `tid_time`       STRING COMMENT '下单时间',
    `pay_time`       STRING COMMENT '支付时间'
) COMMENT 'edb支付事实表'
    PARTITIONED BY (`ds` STRING)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_edb_order_payment'
    TBLPROPERTIES ('orc.compress' = 'snappy');

-- ## 4.电商退单表(事务型事实表)

DROP TABLE IF EXISTS compass_dwd.dwd_edb_order_refund;
CREATE EXTERNAL TABLE IF NOT EXISTS compass_dwd.dwd_edb_order_refund
(
    `tid`                      STRING COMMENT '订单编号',
    `sub_tid`                  STRING COMMENT '子订单编号',
    `out_tid`                  STRING COMMENT '外部平台单号',
    `out_aftersale_id`         STRING COMMENT '外部平台售后单号',
    `aftersale_id`             STRING COMMENT '问题编号',
    `buyer_id`                 STRING COMMENT '买家id',
    `shop_id`                  STRING COMMENT '店铺编号',
    `Shop_name`                STRING COMMENT '仓库名称',
    `return_status`            STRING COMMENT '退货状态',
    `refund_status`            STRING COMMENT '退款状态',
    `online_status`            STRING COMMENT '线上状态',
    `process_status`           STRING COMMENT '处理进度',
    `return_lofistics_company` STRING COMMENT '退回物流公司',
    `return_logistics_number`  STRING COMMENT '退回物流单号',
    `total_goods_refund_fee`   DECIMAL(16, 2) COMMENT '商品退款总额',
    `other_refund_fee`         DECIMAL(16, 2) COMMENT '额外退款金额',
    `actual_refund_fee`        DECIMAL(16, 2) COMMENT '实际退款总金额',
    `return_freight`           DECIMAL(16, 2) COMMENT '退运费',
    `issue_num`                STRING COMMENT '问题数量',
    `arrive_num`               STRING COMMENT '退货到货数量',
    `refund_fee`               STRING COMMENT '商品退款金额',
    `product_id`               STRING COMMENT '产品编号',
    `product_name`             STRING COMMENT '产品名称',
    `item_price`               STRING COMMENT '商品原销售单价',
    `back_flag`                STRING COMMENT '退换补标识',
    `create_time`              STRING COMMENT '创建时间',
    `return_confirm_time`      STRING COMMENT '退货到货时间',
    `agreerefund_time`         STRING COMMENT '同意退款时间'
) COMMENT 'edb退单表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_edb_order_refund'
    TBLPROPERTIES ('orc.compress' = 'snappy');


-- ## 7.adh订单表dwd_adh_order(事务型事实表)


DROP TABLE IF EXISTS compass_dwd.dwd_adh_order;
CREATE EXTERNAL TABLE IF NOT EXISTS compass_dwd.dwd_adh_order
(
    dingdanbianhao   string COMMENT '订单编号',
    quyu             string COMMENT '区域',
    quyujingli       string COMMENT '区域经理',
    qudaoshangbianma string COMMENT '渠道商编号',
    qudaoshang       string COMMENT '渠道商',
    ziqudaoshang     string COMMENT '子渠道商',
    anzhuangmendian  string COMMENT '安装门店',
    zhidanren        string COMMENT '制单人',
    xiadanriqi       string COMMENT '下单日期',
    dingdanzhuangtai string COMMENT '订单状态',
    dingdanbeizhu    string COMMENT '订单备注',
    shouhuodizhi     string COMMENT '收货地址',
    lianxiren        string COMMENT '联系人',
    lianxidianhua    string COMMENT '联系电话',
    kuaidi           string COMMENT '快递',
    kuaididanhao     string COMMENT '快递单号',
    dianshangbianma  string COMMENT '电商编码',
    chanpinbianma    string COMMENT '产品编码',
    chanpinmingcheng string COMMENT '产品名称',
    xinghao          string COMMENT '型号',
    guige            string COMMENT '规格',
    danwei           string COMMENT '单位',
    shuliang         string COMMENT '数量',
    danjia           string COMMENT '单价',
    jine             string COMMENT '金额',
    chanpinleixing   string COMMENT '产品类型'
) COMMENT 'adh订单表'
    PARTITIONED BY (`ds` string)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    STORED AS orc
    LOCATION '/warehouse/compass/compass_dwd.db/dwd_adh_order'
    TBLPROPERTIES ('orc.compress' = 'snappy');
```
