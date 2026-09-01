/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
  -- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cc.cst_id) as customer_key,
	cc.cst_id AS customer_id,
	cc.cst_key AS customer_number,
	cc.cst_firstname AS first_name ,
	cc.cst_lastname AS last_name,
	el.cntry AS country,
	cc.cst_martial_status AS martial_status,
	CASE 
		WHEN cc.cst_gndr != 'n/a' THEN cc.cst_gndr
		ELSE COALESCE(ec.gen,'n/a')
	END gender,
	ec.bdate AS birth_date,
	cc.cst_create_date AS create_date
FROM silver.crm_cust_info as cc
LEFT JOIN silver.erp_cust_az12 ec
ON cc.cst_key = ec.cid
LEFT JOIN silver.erp_loc_a101 el
ON cc.cst_key = el.cid


-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
     DROP VIEW gold.dim_products;
 GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cp.prd_start_dt, cp.prd_id) AS product_key,
	cp.prd_id AS product_id,
	cp.prd_key AS product_number,
	cp.prd_nm AS product_name,
	cp.cat_id AS category_id,
	ep.cat AS category,
	ep.subcat AS sub_category,
	ep.maintenance,
	cp.prd_cost AS product_cost,
	cp.prd_line AS product_line,
	cp.prd_start_dt AS start_date
FROM silver.crm_prd_info cp
LEFT JOIN silver.erp_px_cat_g1v2 ep
ON cp.cat_id = ep.id
WHERE cp.prd_end_dt IS NULL

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
	cs.sls_ord_num AS order_number,
	dp.product_key,
	dc.customer_key,
	cs.sls_order_dt AS order_date,
	cs.sls_ship_dt AS shipping_date,
	cs.sls_due_dt AS due_date,
	cs.sls_sales AS sales,
	cs.sls_quantity AS quantity,
	cs.sls_price AS price
FROM silver.crm_sales_details cs
LEFT JOIN gold.dim_customers dc
ON cs.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_products dp
ON cs.sls_prd_key = dp.product_number


