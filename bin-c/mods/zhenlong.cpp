#include "definitions.h"

namespace mods
{
namespace
{
class ZhenlongMod final : public Definition
{
public:
    int version() const override { return 81; }
    const char* name() const override { return "真龙觉醒"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Awaking of Dragons";
        Music.resize(999, nullptr);
        TitlePosition.x = 200;
        TitlePosition.y = 250;
    }
};
}    //namespace

const Definition& Zhenlong()
{
    static ZhenlongMod mod;
    return mod;
}
}    //namespace mods
