#pragma once

#include <base/types.h>
#include <Core/MySQL/PacketEndpoint.h>
#include <Poco/Net/SocketAddress.h>

#include "config.h"

#if USE_SSL
#    include <Common/Crypto/KeyPair.h>
#endif

namespace DB
{
class Session;

namespace MySQLProtocol
{

namespace Authentication
{

class IPlugin
{
public:
    virtual ~IPlugin() = default;

    virtual String getName() = 0;

    virtual String getAuthPluginData() = 0;

    virtual void authenticate(
        const String & user_name, Session & session, std::optional<String> auth_response,
        std::shared_ptr<PacketEndpoint> packet_endpoint, bool is_secure_connection, const Poco::Net::SocketAddress & address) = 0;
};

/// https://dev.mysql.com/doc/internals/en/secure-password-authentication.html
class Native41 : public IPlugin
{
public:
    Native41();

    Native41(const String & password_, const String & scramble_);

    String getName() override { return "mysql_native_password"; }

    String getAuthPluginData() override { return scramble; }

    void authenticate(
        const String & user_name, Session & session, std::optional<String> auth_response,
        std::shared_ptr<PacketEndpoint> packet_endpoint, bool /* is_secure_connection */, const Poco::Net::SocketAddress & address) override;

private:
    String scramble;
};

#if USE_SSL
/// Caching SHA2 plugin is not used because it would be possible to authenticate knowing hash from users.xml.
/// https://dev.mysql.com/doc/internals/en/sha256.html
class Sha256Password : public IPlugin
{
public:
    Sha256Password(KeyPair & private_key_, LoggerPtr log_);

    String getName() override { return "sha256_password"; }

    String getAuthPluginData() override { return scramble; }

    void authenticate(
        const String & user_name, Session & session, std::optional<String> auth_response,
        std::shared_ptr<PacketEndpoint> packet_endpoint, bool is_secure_connection, const Poco::Net::SocketAddress & address) override;

private:
    KeyPair & private_key;
    LoggerPtr log;
    String scramble;
};
#endif

}

}

}
