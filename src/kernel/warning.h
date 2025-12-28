// Copyright (c) 2024-present The Retardio developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef RETARDIO_KERNEL_WARNING_H
#define RETARDIO_KERNEL_WARNING_H

namespace kernel {
enum class Warning {
    UNKNOWN_NEW_RULES_ACTIVATED,
    LARGE_WORK_INVALID_CHAIN,
    UNKNOWN_NEW_RULES_SIGNAL_VBITS,
    UNKNOWN_NEW_RULES_SIGNAL_INTVER,
    SOFTWARE_EXPIRY,
};
} // namespace kernel
#endif // RETARDIO_KERNEL_WARNING_H
