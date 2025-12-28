// Copyright (c) 2022 The Retardio developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef RETARDIO_KERNEL_CHECKS_H
#define RETARDIO_KERNEL_CHECKS_H

#include <util/result.h>

namespace kernel {

struct Context;

[[nodiscard]] bool Clang_IndVarSimplify_Bug_SanityCheck();

/**
 *  Ensure a usable environment with all necessary library support.
 */
[[nodiscard]] util::Result<void> SanityChecks(const Context&);
} // namespace kernel

#endif // RETARDIO_KERNEL_CHECKS_H
