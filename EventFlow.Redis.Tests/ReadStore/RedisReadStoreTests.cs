﻿using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Configurations;
using DotNet.Testcontainers.Containers;
using EventFlow.Extensions;
using EventFlow.ReadStores;
using EventFlow.Redis.ReadStore;
using EventFlow.Redis.Tests.ReadStore.QueryHandlers;
using EventFlow.Redis.Tests.ReadStore.ReadModels;
using EventFlow.TestHelpers.Aggregates.Entities;
using EventFlow.TestHelpers.Suites;
using Microsoft.Extensions.DependencyInjection;
using NUnit.Framework;
using Redis.OM;
using StackExchange.Redis;

namespace EventFlow.Redis.Tests.ReadStore;

public class RedisReadStoreTests : TestSuiteForReadModelStore
{
    private readonly TestcontainerDatabase _container
        = new TestcontainersBuilder<RedisTestcontainer>().WithDatabase(new RedisTestcontainerConfiguration("redis/redis-stack")
        {
        }).Build();

    protected override Type ReadModelType => typeof(RedisThingyReadModel);

    protected override IServiceProvider Configure(IEventFlowOptions eventFlowOptions)
    {
        _container.StartAsync().Wait();
        var multiplexer = ConnectionMultiplexer.Connect(_container.ConnectionString);
        eventFlowOptions.ConfigureRedis(multiplexer);
        eventFlowOptions.ServiceCollection.AddTransient<ThingyMessageLocator>();
        eventFlowOptions.UseRedisReadStore<RedisThingyReadModel>();
        eventFlowOptions.UseRedisReadStore<RedisThingyMessageReadModel, ThingyMessageLocator>();

        eventFlowOptions.AddQueryHandlers(typeof(RedisThingyGetQueryHandler),
            typeof(RedisThingyGetMessagesQueryHandler), typeof(RedisThingyGetVersionQueryHandler));

        return base.Configure(eventFlowOptions);
    }
}