-- Author:  
-- Date:    
-- Desc:    If trying to load this to SQL server the created_at is in a stange format

select	cast(substring ([created_at],9,2)+' '+substring ([created_at],5,3)+' '+
		substring ([created_at],27,4) +' '+substring ([created_at],12,2) +':'+
		substring ([created_at],15,2)+':'+substring ([created_at],18,2) as datetime) as created_at
from	[dbo].[deptdefence-users]