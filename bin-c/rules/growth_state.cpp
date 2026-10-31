#include "growth_state.h"
#include <algorithm>
#include <cstddef>
#include <stdexcept>

namespace rules::growth
{
namespace
{
// Four nonnegative 15-bit quantities: seed32 | checksum12 | tag/version16.
constexpr uint64_t tag = 0x4751;
constexpr uint16_t halfTag = 0x5000;
static_assert(sizeof(TRole) == 182);
static_assert(offsetof(TRole, UnUse) == 6);
static_assert(offsetof(TRole, TakingItemAmount) == 174);

uint32_t mix(uint32_t x)
{
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    return x ^ (x >> 16);
}

uint32_t checksum(uint32_t seed) { return mix(seed ^ 0x47524e47u) & 0xfffu; }

bool emptyInventory(const TRole& hero)
{
    return std::all_of(std::begin(hero.TakingItem), std::end(hero.TakingItem), [](int id) { return id == -1; });
}

uint64_t packed(const TRole& hero)
{
    uint64_t value = 0;
    for (int i = 0; i < 4; ++i)
        value |= uint64_t(uint16_t(hero.TakingItemAmount[i]) & 0x7fff) << (15 * i);
    return value;
}

bool tagged(const TRole& hero) { return (packed(hero) >> 48) == (tag >> 4); }
}

bool HasSeed(const TRole& hero)
{
    if (!emptyInventory(hero)) return false;
    for (int count : hero.TakingItemAmount) if (count < 0) return false;
    uint64_t value = packed(hero);
    return (value >> 44) == tag && ((value >> 32) & 0xfff) == checksum(uint32_t(value));
}

uint32_t ReadSeed(const TRole& hero)
{
    if (!HasSeed(hero)) throw std::runtime_error("Missing or damaged growth RNG metadata in role 0 personal item quantities");
    return uint32_t(packed(hero));
}

void WriteSeed(TRole& hero, uint32_t seed)
{
    if (!emptyInventory(hero)) throw std::runtime_error("Fixed growth RNG requires all four role 0 personal item IDs to be -1");
    uint64_t value = uint64_t(seed) | (uint64_t(checksum(seed)) << 32) | (tag << 44);
    for (int i = 0; i < 4; ++i) hero.TakingItemAmount[i] = int16_t((value >> (15 * i)) & 0x7fff);
}

void PrepareLoadedRoles(std::span<TRole> roles)
{
    if (!HasConfigurableGrowth() || roles.empty() || HasSeed(roles[0])) return;
    if (tagged(roles[0])) throw std::runtime_error("Damaged or unsupported growth RNG metadata; restore an unmodified save");
    if (!emptyInventory(roles[0]))
    {
        if (GetGrowthMode() == GrowthMode::FixedRandom)
            throw std::runtime_error("Role 0 personal inventory conflicts with fixed growth RNG storage");
        return;
    }
    // Migrate before play, hashing the loaded records instead of time or battle RNG.
    // Reopening the same old save therefore imports exactly the same seed.
    uint32_t hash = 2166136261u;
    for (std::byte byte : std::as_bytes(roles)) hash = (hash ^ std::to_integer<uint8_t>(byte)) * 16777619u;
    WriteSeed(roles[0], mix(hash));
}

void StartCampaign(std::span<TRole> roles, uint32_t seed)
{
    if (!HasConfigurableGrowth() || roles.empty()) return;
    if (!emptyInventory(roles[0]))
    {
        if (GetGrowthMode() == GrowthMode::FixedRandom)
            throw std::runtime_error("Role 0 personal inventory conflicts with fixed growth RNG storage");
        return;
    }
    WriteSeed(roles[0], seed);
    for (auto& role : roles)
        if (uint16_t(role.UnUse) == halfTag || uint16_t(role.UnUse) == (halfTag | 1)) StoreHalf(role, false);
}

bool HasHalf(const TRole& role) { return uint16_t(role.UnUse) == (halfTag | 1); }
void StoreHalf(TRole& role, bool half) { role.UnUse = int16_t(halfTag | int(half)); }

int FixedDraw(uint32_t seed, int roleIndex, int targetLevel, int group, int bound)
{
    if (roleIndex < 0 || roleIndex >= 2032 || targetLevel < 1 || targetLevel > 100 || group < 0)
        throw std::runtime_error("Invalid fixed growth draw identity");
    if (bound <= 1) return 0;
    // Stable group IDs isolate rolls even when eligibility changes. Rejection
    // sampling avoids modulo bias and never consumes the battle RNG stream.
    uint32_t value = mix(seed ^ 0xa511e9b3u);
    value = mix(value ^ uint32_t(roleIndex) * 0x9e3779b9u);
    value = mix(value ^ uint32_t(targetLevel) * 0x85ebca6bu);
    value = mix(value ^ uint32_t(group) * 0xc2b2ae35u);
    uint32_t limit = (0u - uint32_t(bound)) % uint32_t(bound);
    for (uint32_t retry = 0; value < limit; ++retry) value = mix(value + 0x9e3779b9u + retry);
    return int(value % uint32_t(bound));
}

void CheckPersonalItemWrite(int roleIndex)
{
    if (roleIndex == 0 && HasConfigurableGrowth() && tagged(Rrole[0]))
        throw std::runtime_error("Instruction 41 cannot use role 0 personal inventory reserved for growth RNG; use the shared inventory");
}
}
