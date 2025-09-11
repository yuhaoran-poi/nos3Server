---@class Composite_cfg
---@field public id integer @ID(必须为第一列且名称为id，类型为INT) 合成下标最大范围=合成目标ID*100+i 其中i-1表示第几种方式 80000*100+0表示第1种合成方式 80000*100+50表示第49种合成方式
---@field public max_num integer @一次合成操作的最大数量（为了节省服务器消耗最大20）
---@field public item_id integer @合成物品ID
---@field public num integer @合成数量
---@field public cost table @一次合成的消耗
---@field public rate integer @合成成功率0~10000
---@field public show_ui integer @是否展示在合成界面 0-不展示 1-制造 2-合成
return {
[60000100] = { id=60000100,max_num=10,item_id=600001,num=1,cost={[22001]=10},rate=10000,show_ui=1 },
[60000200] = { id=60000200,max_num=10,item_id=600002,num=1,cost={[22006]=10},rate=10000,show_ui=1 },
[60000300] = { id=60000300,max_num=10,item_id=600003,num=1,cost={[22005]=10},rate=10000,show_ui=1 },
[100000000] = { id=100000000,max_num=1,item_id=1000000,num=1,cost={[23001]=10,[1]=1002},rate=10000,show_ui=0 },
[100000100] = { id=100000100,max_num=1,item_id=1000001,num=1,cost={[23002]=10,[1]=1000},rate=10000,show_ui=0 },
[100000200] = { id=100000200,max_num=1,item_id=1000002,num=1,cost={[23003]=10,[1]=1001},rate=10000,show_ui=0 },
[100000300] = { id=100000300,max_num=1,item_id=1000003,num=1,cost={[23004]=10,[1]=1000},rate=10000,show_ui=0 },
[100000400] = { id=100000400,max_num=1,item_id=1000004,num=1,cost={[23005]=10,[1]=1000},rate=10000,show_ui=0 },
[9500000] = { id=9500000,max_num=10,item_id=95000,num=1,cost={[24015]=10},rate=10000,show_ui=2 },
[9500100] = { id=9500100,max_num=10,item_id=95001,num=1,cost={[24016]=10},rate=10000,show_ui=2 },
[9500200] = { id=9500200,max_num=10,item_id=95002,num=1,cost={[24017]=10},rate=10000,show_ui=2 }
}