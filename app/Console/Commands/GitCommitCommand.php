<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class GitCommitCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'commit {message : Commit message}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Add all changes, dump database, and commit with a given message';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $message = $this->argument('message');

        // Get database configuration from .env
        $dbHost = config('database.connections.mysql.host');
        $dbUser = config('database.connections.mysql.username');
        $dbPassword = config('database.connections.mysql.password');
        $dbName = config('database.connections.mysql.database');

        // Run mysqldump to create a database backup
        /*$dumpCommand = "mysqldump -h $dbHost -u $dbUser -p$dbPassword $dbName > {$dbName}_backup.sql";
        $dumpResult = shell_exec($dumpCommand);
        if ($dumpResult === false) {
            $this->error('Failed to create database backup. Please check your configuration and try again.');
            return 1;
        }
        $this->info('Database backup created.');*/

        // Run git add -A
        $addResult = shell_exec('git add -A');
        if ($addResult === false) {
            $this->error('Failed to add changes to git.');
            return 1;
        }
        $this->info('Changes added to git.');

        // Run git commit -m
        $commitResult = shell_exec("git commit -m \"$message\"");
        if ($commitResult === false) {
            $this->error('Failed to commit changes.');
            return 1;
        }
        $this->info($commitResult);

        return 0;
    }}
