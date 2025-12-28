// Copyright (c) 2011-2020 The Retardio developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef RETARDIO_QT_BITCOINADDRESSVALIDATOR_H
#define RETARDIO_QT_BITCOINADDRESSVALIDATOR_H

#include <QValidator>

#include <vector>

/** Base58 entry widget validator, checks for valid characters and
 * removes some whitespace.
 */
class BitcoinAddressEntryValidator : public QValidator
{
    Q_OBJECT

public:
    explicit BitcoinAddressEntryValidator(QObject *parent);

    virtual State validate(QString &input, std::vector<int>&error_locations) const;
    virtual State validate(QString &input, int &pos) const override;
};

/** Retardio address widget validator, checks for a valid retardio address.
 */
class BitcoinAddressCheckValidator : public BitcoinAddressEntryValidator
{
    Q_OBJECT

public:
    explicit BitcoinAddressCheckValidator(QObject *parent);

    using BitcoinAddressEntryValidator::validate;
    State validate(QString &input, std::vector<int>&error_locations) const override;
};

#endif // RETARDIO_QT_BITCOINADDRESSVALIDATOR_H
