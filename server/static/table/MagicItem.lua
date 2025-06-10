---@class MagicItem_cfg
---@field public id integer @成品法器（最大50种-每种类型占500个）法器需要鉴定，鉴定后每把法器的词条不相同 （每个类型第一个ID为默认法器，即当角色没有装备法器时默认装配的法器） 101-剑：500000~500500 102-拂尘：500500~501000 103-伞：501000~501500 104-鞭：501500~502000 105-弹弓：502000~502500 106-双枪：502500~503000 107-关刀：503000~503500 108-长枪：503500~504000 109-弓箭：504000~504500 110-刀：504500~505000 111-扇子：505000~505500 112-重剑：505500~506000
---@field public maxlv integer @最大等级
---@field public identifycost table @鉴定消耗
---@field public alltagnum integer @随机词条数量
---@field public durability integer @耐久值
---@field public sturdy integer @坚固值
return {
[500000] = { id=500000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[500001] = { id=500001,maxlv=20,identifycost={[1]=1001,[51001]=1},alltagnum=5,durability=50,sturdy=100 },
[500002] = { id=500002,maxlv=25,identifycost={[1]=1002,[51002]=1},alltagnum=5,durability=50,sturdy=100 },
[500003] = { id=500003,maxlv=30,identifycost={[1]=1003,[51003]=1},alltagnum=5,durability=50,sturdy=100 },
[500500] = { id=500500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[500501] = { id=500501,maxlv=20,identifycost={[1]=1005,[51501]=1},alltagnum=5,durability=50,sturdy=100 },
[500502] = { id=500502,maxlv=25,identifycost={[1]=1006,[51502]=1},alltagnum=5,durability=50,sturdy=100 },
[500503] = { id=500503,maxlv=30,identifycost={[1]=1007,[51503]=1},alltagnum=5,durability=50,sturdy=100 },
[501000] = { id=501000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[501001] = { id=501001,maxlv=20,identifycost={[1]=1009,[52001]=1},alltagnum=5,durability=50,sturdy=100 },
[501002] = { id=501002,maxlv=25,identifycost={[1]=1010,[52002]=1},alltagnum=5,durability=50,sturdy=100 },
[501003] = { id=501003,maxlv=30,identifycost={[1]=1011,[52003]=1},alltagnum=5,durability=50,sturdy=100 },
[501500] = { id=501500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[501501] = { id=501501,maxlv=20,identifycost={[1]=1013,[52501]=1},alltagnum=5,durability=50,sturdy=100 },
[501502] = { id=501502,maxlv=25,identifycost={[1]=1014,[52502]=1},alltagnum=5,durability=50,sturdy=100 },
[501503] = { id=501503,maxlv=30,identifycost={[1]=1015,[52503]=1},alltagnum=5,durability=50,sturdy=100 },
[501504] = { id=501504,maxlv=30,identifycost={[1]=1015,[52504]=1},alltagnum=5,durability=50,sturdy=100 },
[502000] = { id=502000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[502001] = { id=502001,maxlv=20,identifycost={[1]=1016,[53001]=1},alltagnum=5,durability=50,sturdy=100 },
[502500] = { id=502500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[502501] = { id=502501,maxlv=20,identifycost={[1]=1019,[53501]=1},alltagnum=5,durability=50,sturdy=100 },
[503000] = { id=503000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[503001] = { id=503001,maxlv=20,identifycost={[1]=1021,[54001]=1},alltagnum=5,durability=50,sturdy=100 },
[503500] = { id=503500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[503501] = { id=503501,maxlv=20,identifycost={[1]=1021,[54501]=1},alltagnum=5,durability=50,sturdy=100 },
[504000] = { id=504000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[504001] = { id=504001,maxlv=20,identifycost={[1]=1025,[55001]=1},alltagnum=5,durability=50,sturdy=100 },
[504500] = { id=504500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[504501] = { id=504501,maxlv=20,identifycost={[1]=1027,[55501]=1},alltagnum=5,durability=50,sturdy=100 },
[505000] = { id=505000,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[505001] = { id=505001,maxlv=20,identifycost={[1]=1029,[56001]=1},alltagnum=5,durability=50,sturdy=100 },
[505500] = { id=505500,maxlv=1,identifycost={},alltagnum=5,durability=50,sturdy=100 },
[505501] = { id=505501,maxlv=20,identifycost={[1]=1031,[56501]=1},alltagnum=5,durability=50,sturdy=100 }
}