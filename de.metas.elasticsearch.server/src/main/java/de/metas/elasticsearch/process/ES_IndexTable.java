package de.metas.elasticsearch.process;

import java.util.Collection;

import org.compiere.model.I_AD_Table;

import de.metas.elasticsearch.indexer.IESModelIndexer;
import de.metas.process.Process;

/*
 * #%L
 * de.metas.business
 * %%
 * Copyright (C) 2016 metas GmbH
 * %%
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program. If not, see
 * <http://www.gnu.org/licenses/gpl-2.0.html>.
 * #L%
 */

/**
 * SysAdmin process used to completely index a given table using all registered model indexers.
 *
 * @author metas-dev <dev@metasfresh.com>
 *
 */
@Process
public class ES_IndexTable extends AbstractModelIndexerProcess
{
	@Override
	protected Collection<IESModelIndexer> getModelIndexers()
	{
		final I_AD_Table adTable = getRecord(I_AD_Table.class);
		final String modelTableName = adTable.getTableName();
		return modelIndexingService.getModelIndexersByTableName(modelTableName);
	}
}
