# Plaintext accounting example

This is a simple fictious example to demonstrate some concepts around [plaintextaccounting](https://plaintextaccounting.org/) using [beancount](https://github.com/beancount/beancount). Whatever similarities any transactions might have to real ones is only coincidence.


## Overview

The idea of this repository is that you can follow the various commits that have been made, and whatever commentary is provided here to make sense of things. That's the idea at least, let's see how that goes.


## Double-entry accounting

We assume you already know what [double-entry accounting](https://en.wikipedia.org/wiki/Double-entry_bookkeeping) is, if not I encourage you to head on over there and have a quick read to bring yourself up to speed.

TL;DR;
> Double-entry accounting is a method of bookkeeping that relies on a two-sided accounting entry to maintain financial information. Every entry to an account requires a corresponding and opposite entry to a different account.

A trivial example of this could look like the following

```
  Assets:GothamNational:Account    -3.50 EUR
  Expenses:FoodDrinks:Coffee        3.50 EUR
```

From this example, you can see a debit from `Assets:GothamNational:Account` and a credit to `Expenses:FoodDrinks:Coffee` and that these values match. That's the core concept of double entry accounting, that these two entries match each other and balance to zero. In truth, you can have more than two legs/entries to a transaction, but the rule remains the same, the sum of those entries should total to zero for any valid transaction.


## Plaintext accounting

> Plain text accounting means doing accounting with plain text data formats and scriptable software, in the style of Ledger, hledger, beancount, and co.

If you want a more exhaustive introduction to plaintext accounting, I would encourage you to head over to plaintextaccounting.org and read up more there.

Although there are many options to choose from I've opted for beancount, so that will be the basis for the examples in this repo. You're of course free to choose whatever tool works best for you.


## Laying out your ledgers
The lay out my ledgers actually goes against the official beancount advice, in that I have split my ledgers across multiple files, and use the `include` directive to pull them together, which has some downsides which we will discuss.

The obvious downsides to this approach are:
 - You can't point at an imported file directly, you have to reference the main.bean file for everything, so this isn't super flexible
 - Per above, some tools do not handle the imports well/or at all; e.g. bean-doctor, bean-check, etc.
 - Some advanced `option` statements will have to be used carefully, as the imports aren't handled in a deterministic way, hence you'll be limited in using these if you want to put them in the imported files. Many GitHub issues threads about this one :|  Simple solution is to keep all options in your main beancount file, simple!

The upsides to splitting the files are numerous, and in my opinion outweigh the downsides:
 - You don't have all your ledger/statements in a single file, this seems obvious, sure you can set up some folding in your editor or whatever, but navigating some 10,000+ line file gets not fun quickly
 - If you're importing statements from external sources, and then generating the ledgers, being able to do that with a small blast radius is desirable. Also being able to regenerate, diff, etc that resulting file is useful, which we loose if we're dealing with a single mega ledger
 - When you ultimately want to truncate your ledger you can easily do this, without having to delete the old statements/data. It's as simple as removing the `include` statement that includes the ledger file, and updating the main/parent ledger with a pad and balance directive to match the balance at the end of the period being removed


## Importing my bank transactions
There are plenty of utilties that will connect to supported banking institutions and export your transacations for oyu. I however like to play it safe, and prefer to do the manual route, and simply log into my various banks, and use their export transactions functionality to export my transactions in CSV and then use that to generate my beancount statements from the CSV.

I believe this approach has several desirable properties:
 - I am not having to trust my banking credentials with any third party tools or other weird things
 - The CSV export is the source of truth, I have that as a reference going forward, and can then generate the beancount statements from that source of truth. And I can re-run and check that process as often as I like with this approach
 - This workflow should feel very natural for anyone coming from a development/devops/similar coding background

Some things I do that might differ from others, but that I believe help me in making this not be too much overhead, and keeping things manageable are the following:
 - The interval/frequency that I export my transactions on; I only do this once per quarter, thus I only have to do this four times per year, which to me seems reasonable for the benefits it brings me
 - How I organise the files to help with the next two tasks; I use a very prescriptive naming scheme for the bank exports to help with converting these into beancount format later, and that ties in with the automation/helpers I'll explain later as well
 - How I convert these bank exports into beancount format, I use a tool called `csv2beancount` that I wrote to help with this tasks, there are others like it but this one is mine ;)
 - Some simple conventions I use to help automate this with Make; the naming scheme, the tooling of choice, has meant that I can save the bank exports to a directory, and run `make` and the 


## Handling imported transactions
So you've converted some bank transactions into beancount format, but how do you handle aligning/validating these transactions?

First we need to determine, is this the opening/first transactions in your ledger, or do you already have some. If this is the first, then we're going to need to determine the opening balance and `pad` the account to magically have that balance so that the subsequent transactions afterwards will have the correct funds available to balance.

Secondly regardless of whether this is the opening/first transactions or not, we want to have a `balance` assertion to specify what the balance should be at that time, and have beancount enforce that the balance does match that, or else it throws an error for us. This is super useful, as what's the point of maintaining these ledgers if the totals aren't correct and verified!

The third thing we have to learn to deal with when importaing statements, is how to reconsile when we have multiple bank accounts that we're importing statements from, and when those accounts have transactions that overlap/reference each other between them. Can you see what the issue is with this? If you guessed that we'd essentially have duplicate transactions then you guesssed right, we'll have twice as much added/deducated as we intended. Now as for how to handle this, there are two approaches I have used, each has their pros and cons, so I'll cover both and let you decide whichever you prefer.

The first option is to prefer one account/ledger over the other, and simply comment the other side/duplicate transaction out and then the account(s) will balance again as intended. This is nice and simple on the one hand, but has the slight downside of meaning that we have to comment out a statement, and means the two accounts are herein linked in some way, i.e. account-a depends on a transaction from account-b to balance correctly. This is fine on face value, but if you intend to truncate your journals after some period, you might not like this.

An example of this approach would essentialy be the following:

```
  ; From the GothamNational ledger file
  Assets:GothamNational:Account    -100.00 EUR
  Assets:IronBank:Account           100.00 EUR

  ; From the IronBank ledger file
  ; Assets:GothamNational:Account   -100.00 EUR
  ; Assets:IronBank:Account          100.00 EUR
```

The second option is to modify both transactions slighty in such instances, and use a clearing account to settle the transactions that cross accounts. The clearing account is just a virtual made up account, that you can use to settle transactions like this that cross accounts. The clearing account must always balance to zero, and you would simply update each transaction to reference the clearing account rather than the second account on each side. This has the advantage that each of the transactions can remain in their respective ledgers, and you still arrive at the correct balance, and have a robust way of checking that no mistakes are introduced. You can even add a balance assertion on the clearing account to make sure it always balancees to zero.

An example of this approach would look like the following:

```
  ; From the GothamNational ledger file
  Assets:GothamNational:Account    -100.00 EUR
  Liabilities:Clearings             100.00 EUR

  ; From the IronBank ledger file
  Liabilities:Clearings            -100.00 EUR
  Assets:IronBank:Account           100.00 EUR
```


## Local tooling and helpers
To make working with beancount easier and more repeatable, I've created some local helpers with Make and Docker to aid in running the fava web-ui, and other tools. This has the benefit of making things very repeatable and portable. Examples of these are:

 - fava-docker
 - bean-web-docker
 - bean-check-docker
 - bean-report-docker
 - bean-format-docker

And each of those has a non-docker version as well if you'd prefer to run it locally also.
