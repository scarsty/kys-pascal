# C++ MOD 定义

每个已知 MOD 在 `bin-c/mods/` 中有自己的文件，集中定义身份、标题、资源限制、角色创建、姓名奖励、移动、菜单和事件兼容行为。

| MODVersion | MOD | 定义文件 |
| --- | --- | --- |
| 0 | 原版 | `base.cpp` |
| 11 | 小猪闯江湖 | `xiaozhu.cpp` |
| 12 | 苍龙逐日 | `dragon.cpp` |
| 21 | 天书奇侠 | `tianshu_qixia.cpp` |
| 22 | 菠萝三国 | `boluo_sanguo.cpp` |
| 23 | 笑梦游记 | `xiaomeng.cpp` |
| 31 | 再战江湖 | `zaizhan.cpp` |
| 41 | PTT | `ptt.cpp` |
| 51 | 魏征 | `weizheng.cpp` |
| 71 | 天书劫 | `tianshu_jie.cpp` |
| 72 | Shake the World | `shake_world.cpp` |
| 81 | 真龙觉醒 | `zhenlong.cpp` |
| 91 | 问情 | `wenqing.cpp` |
| 100 | 其他 | `other.cpp` |

`mod.h` 定义引擎使用的行为接口，`registry.cpp` 注册各 MOD，`mod.cpp` 提供共享默认行为并解析配置。引擎通过 `mods::Active()` 使用当前 MOD，不在角色创建、移动、菜单或事件代码中检查 MOD 编号。`version()` 对应 INI 中的 `MODVersion`，`name()` 提供 MOD 名称。

没有专属行为的方法继承共享默认实现；特殊行为在对应 MOD 文件中覆盖。原版与编号 100 共享的角色奖励由 `base.cpp` 的 `ApplyBaseCharacterSetup` 提供。未列出的非负编号仍保留各自编号，使用 `other.cpp` 中的默认行为，不会自动继承编号 100 的姓名奖励。

苍龙统一使用 DOS 1.2 的战斗、成长和初始属性，保留四档成长自定义及特殊姓名扩展，详见[苍龙逐日](苍龙逐日.md)。其他 MOD 保持现有复刻引擎的规则和数值，按各自文件添加例外。规则计算的共享实现保留在 `bin-c/rules/`，由 MOD 定义选择。

角色创建分为抽取和确认后的设置。`createStartingStats` 负责初始抽取，`applySpecialStartingStats` 在预览前应用主角的特殊姓名属性并锁定确认；`finishCharacterCreation` 在确认后应用其他角色、物品和武功的修改，以及苍龙的成长种子初始化。

`bin-c/tests/mod_tests.cpp` 覆盖所有已知 MOD 的注册、标题、资源限制、初始属性范围与 RNG 消耗、姓名奖励、移动及事件差异；苍龙的战斗、成长和存档细节由 `dragon_rules_tests.cpp` 覆盖。测试使用构造数据，不代表已对全部 MOD 的完整游戏数据进行通关验证。
