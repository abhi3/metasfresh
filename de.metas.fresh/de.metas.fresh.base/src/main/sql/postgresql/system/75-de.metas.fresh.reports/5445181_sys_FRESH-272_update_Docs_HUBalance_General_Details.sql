
DROP FUNCTION IF EXISTS de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details(numeric, numeric, numeric, numeric,  date, date, date);
DROP FUNCTION IF EXISTS de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details(numeric, numeric, numeric, numeric, character varying, date, date, date);

DROP TABLE IF EXISTS de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details;

-- Table: de_metas_endcustomer_fresh_reports.docs_hubalance_report_details

CREATE TABLE de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details
(
  bpartner character varying,
  documentno character varying,
  printname character varying,
  movementdate date,
  "name" character varying,
  outgoing numeric,
  incoming numeric,
  carryoutgoing numeric,
  carryincoming numeric,
  uomsymbol character varying
)
WITH (
  OIDS=FALSE
);


-- Function: de_metas_endcustomer_fresh_reports.docs_hubalance_report_general_details(numeric, numeric, numeric, numeric, character varying, date, date, date)

CREATE OR REPLACE FUNCTION de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details
(
	m_material_balance_config_id numeric, --$1
	c_bpartner_id numeric,  --$2
	C_BP_Group_ID numeric,  --$3
	M_Product_ID numeric,  --$4
	isGebindeFlatrate character varying,  --$5
	startdate date,  --$6
	enddate date,  --$7
	refdate date  --$8
)
  RETURNS SETOF de_metas_endcustomer_fresh_reports.Docs_HUBalance_Report_General_Details AS
$BODY$

select  bpartner, 
	documentno,
	printname,
	MovementDate,
	Name, --Product
	Outgoing,
	Incoming,
	max(CarryOutgoing) over(partition by bpartner, name),
	max(CarryIncoming) over(partition by bpartner, name),
	UOMSymbol
from (
SELECT
	x.bpartner, 
	COALESCE(x.DocumentNo, '') as documentno,
	COALESCE(x.PrintName, '') as printname,
	x.MovementDate::date,	
	x.Name, --Product
	SUM(COALESCE(x.Outgoing, 0)) as Outgoing,
	SUM(COALESCE(x.Incoming, 0)) as Incoming,
	SUM(COALESCE( x.CarryOutgoing, 0 )) AS CarryOutgoing,
	SUM(COALESCE( x.CarryIncoming, 0 )) AS CarryIncoming,
	x.UOMSymbol as UOMSymbol,
	x.m_product_id,
	x.C_BPartner_ID
FROM

	(
		SELECT	
		mbd.C_BPartner_ID,
		bp.name as bpartner, 
		null as DocumentNo,
		null as PrintName,
		null as MovementDate,
		p.M_Product_ID,
		p.Name, --Product
		SUM (mbd.QtyOutgoing) AS CarryOutgoing,
		SUM (mbd.QtyIncoming) AS CarryIncoming,
		null as Outgoing,
		null as Incoming,
		null as UOMSymbol 
		
		FROM	M_Material_Balance_Detail mbd
			INNER JOIN M_Material_Balance_Config mbc ON mbd.M_Material_Balance_Config_ID = mbc.M_Material_Balance_Config_ID
			INNER JOIN C_BPartner bp on mbd.C_BPartner_ID = bp.C_BPartner_ID
			INNER JOIN M_Product p ON mbd.M_Product_ID = p.M_Product_ID and case when  $4 >0 then p.M_Product_ID = $4 else 1=1 end

		WHERE	MovementDate::date < $6 AND ( mbd.IsReset = 'N' OR ( mbd.IsReset = 'Y' AND mbd.ResetDateEffective > $7 ))
		GROUP BY  mbd. C_BPartner_ID,
	bp.name, 
	p.M_Product_ID,
	p.Name
	
	
	
	
	UNION ALL
	( Select 
		mbd. C_BPartner_ID,
		bp.name as bpartner, 
		mbd.DocumentNo,
		dt.PrintName,
		mbd.MovementDate::date,
		p.M_Product_ID,
		p.Name, --Product
		null AS CarryOutgoing,
		null AS CarryIncoming,
		SUM (mbd.QtyOutgoing) AS Outgoing,
		SUM (mbd.QtyIncoming) AS Incoming,
		UOMSymbol
	
	FROM
		M_Material_Balance_Config mbc
		INNER JOIN M_Material_Balance_Detail mbd ON mbc.M_Material_Balance_Config_ID = mbd.M_Material_Balance_Config_ID
		INNER JOIN C_BPartner bp on mbd.C_BPartner_ID = bp.C_BPartner_ID
		INNER JOIN C_UOM uom ON mbd.C_UOM_ID = uom.C_UOM_ID
		INNER JOIN C_DocType dt ON mbd.C_DocType_ID = dt.C_DocType_ID
		INNER JOIN M_Product p ON mbd.M_Product_ID = p.M_Product_ID and case when  $4 >0 then p.M_Product_ID = $4 else 1=1 end
		INNER JOIN M_InOutLine iol ON mbd.M_InOutLine_ID = iol.M_InOutLine_ID
		
	WHERE
		mbc.M_Material_Balance_Config_ID = $1
		AND mbd.isActive = 'Y'
		AND ( mbd.IsReset = 'N' OR ( mbd.IsReset = 'Y' AND mbd.ResetDateEffective > $6 ))
		AND (
			case when $2 > 0 
			then mbd.C_BPartner_ID = $2
			else
			1=1
			end
			)
		AND (
			case when $3 > 0
			then $3 = (Select bp.C_BP_Group_ID from C_BPartner bp where bp.C_BPartner_ID = mbd.C_BPartner_ID)
			else 1=1
			end
			)
		AND COALESCE( mbd.MovementDate::date >= $6, true )
		AND COALESCE( mbd.MovementDate::date <= $7, true )
		
			
GROUP BY
	mbd. C_BPartner_ID,
	bp.name, 
	p.M_Product_ID,
	p.Name,
	mbd.DocumentNo,
	dt.PrintName,
	mbd.MovementDate,
	
	UOMSymbol
		
		
	) 

)x


WHERE 1=1 
	AND (
			case when $2 > 0 
			then x.C_BPartner_ID = $2
			else
			1=1
			end
			)
		AND (
			case when $3 > 0
			then $3 = (Select bp.C_BP_Group_ID from C_BPartner bp where bp.C_BPartner_ID = x.C_BPartner_ID)
			else 1=1
			end
			)
		and case when  $4 >0 then x.M_Product_ID = $4 else 1=1 end

		and (
			case when $5 = 'Y' then
				(select * from de_metas_endcustomer_fresh_reports.exists_flatrateterm_for_product_and_bpartner(x.m_product_id, x.C_BPartner_ID, $6, $7 ))
			when $5 = 'N' then
			(
				not (select * from de_metas_endcustomer_fresh_reports.exists_flatrateterm_for_product_and_bpartner(x.m_product_id, x.C_BPartner_ID, $6, $7 ))
			)
			else 
			(
				1=1
			)
					
				end
			)
		
GROUP BY
	x.bpartner,
	x.C_BPartner_ID,
	COALESCE(x.DocumentNo, ''),
	COALESCE(x.PrintName, ''),
	x.MovementDate::date,
	x.Name, --Product
	x.m_product_id,
	x.UOMSymbol
Order by 

	x.bpartner,
	x.name,
	x.movementDate

)rez
order by 
rez.bpartner, rez.name, rez.movementDate, rez.documentno, rez.printname, rez.CarryIncoming, rez.CarryOutgoing, rez.UOMSymbol 
  $BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;