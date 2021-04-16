/*
 * Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

using System;
using System.IO;
using System.Linq;
using Amazon.Kinesis.Model;
using Microsoft.Extensions.Configuration;

/// <summary>
/// <para> Before running the code:
/// Fill in your AWS access credentials in the provided credentials file template,
/// and be sure to move the file to the default location under your home folder --
/// C:\users\username\.aws\credentials on Windows -- where the sample code will
/// load the credentials from.
/// https://console.aws.amazon.com/iam/home?#security_credential
/// </para>
/// <para>
/// WARNING:
/// To avoid accidental leakage of your credentials, DO NOT keep the credentials
/// file in your source directory.
/// </para>
/// </summary>

namespace Amazon.Kinesis.ClientLibrary.SampleProducer
{
    /// <summary>
    /// A sample producer of Kinesis records.
    /// </summary>
    class SampleRecordProducer
    {


        /// <summary>
        /// The AmazonKinesisClient instance used to establish a connection with AWS Kinesis,
        /// create a Kinesis stream, populate it with records, and (optionally) delete the stream.
        /// The SDK attempts to fetch credentials in the order described in:
        /// http://docs.aws.amazon.com/sdkfornet/latest/apidocs/items/MKinesis_KinesisClientctorNET4_5.html.
        /// You may also wish to change the RegionEndpoint.
        /// </summary>
        private static readonly AmazonKinesisClient kinesisClient = new AmazonKinesisClient(RegionEndpoint.USEast1);

        /// <summary>
        /// This method verifies your credentials, creates a Kinesis stream, waits for the stream
        /// to become active, then puts 10 records in it, and (optionally) deletes the stream.
        /// </summary>
        public static void Main(string[] args)
        {
            new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile($"appSettings.json", optional: false, reloadOnChange: false)
                .Build();

            //arn:aws:kinesis:us-west-1:489080471675:stream/kinesis-stream
            const string myStreamName = "kinesis-stream";
            const int myStreamSize = 1;

                        
            Console.Error.WriteLine("Putting records in stream : " + myStreamName);
            // Write 10 UTF-8 encoded records to the stream.
            //for (int j = 0; j < 10; ++j)
            {
                PutRecordRequest requestPutRecord = new PutRecordRequest();
                requestPutRecord.StreamName = myStreamName;
                requestPutRecord.Data = new MemoryStream(File.ReadAllBytes("D:\\Work\\Kinesis\\SampleMessages.txt"));
                requestPutRecord.PartitionKey = "partitionKey-" + 0;//j;
                var putResultResponse = kinesisClient.PutRecordAsync(requestPutRecord).Result;
                Console.Error.WriteLine(
                    String.Format("Successfully putrecord {0}:\n\t partition key = {1,15}, shard ID = {2}",
                        0, requestPutRecord.PartitionKey, putResultResponse.ShardId));

                GetShardIteratorRequest shardReq = new GetShardIteratorRequest();
                shardReq.StreamName = myStreamName;
                shardReq.ShardId = putResultResponse.ShardId;
                shardReq.ShardIteratorType = ShardIteratorType.TRIM_HORIZON;
                GetRecordsRequest requestGetRecords = new GetRecordsRequest();
                requestGetRecords.Limit = 5000;
                requestGetRecords.ShardIterator = kinesisClient.GetShardIteratorAsync(shardReq).Result.ShardIterator;
                var result = kinesisClient.GetRecordsAsync(requestGetRecords).Result;
                Console.Error.WriteLine("Successfully read records: \n" + string.Join("\n", result.Records.Select(r => new StreamReader(r.Data).ReadToEnd())));
            }

        }
    }
}