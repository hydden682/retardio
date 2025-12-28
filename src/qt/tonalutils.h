// Copyright (c) 2016 The Retardio developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef RETARDIO_QT_TONALUTILS_H
#define RETARDIO_QT_TONALUTILS_H

#include <QValidator>

QT_BEGIN_NAMESPACE
class QFont;
class QString;
QT_END_NAMESPACE

class TonalUtils
{
public:
    static bool font_supports_tonal(const QFont& font);

    static QValidator::State validate(QString&input, int&pos);

    static void ConvertFromHex(QString&);
    static void ConvertToHex(QString&);
};

#endif // RETARDIO_QT_TONALUTILS_H
