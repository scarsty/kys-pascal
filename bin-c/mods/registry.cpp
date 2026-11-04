#include "definitions.h"
#include <array>

namespace mods
{
const Definition& Find(int version)
{
    using Factory = const Definition& (*)();
    static constexpr std::array<Factory, 14> definitions{
        Base, Xiaozhu, Dragon, TianshuQixia, BoluoSanguo, Xiaomeng, Zaizhan,
        Ptt, Weizheng, TianshuJie, ShakeWorld, Zhenlong, Wenqing, Other
    };
    for (auto definition : definitions)
    {
        const auto& mod = definition();
        if (mod.version() == version) return mod;
    }
    return Unspecified(version);
}
}    //namespace mods
