SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
CREATE DATABASE `denice_twitter` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `denice_twitter`;

CREATE TABLE `dictionary` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `Word1` text NOT NULL,
  `Word2` text NOT NULL,
  `Word3` text NOT NULL,
  `DateAdded` int(11) NOT NULL,
  PRIMARY KEY (`Index`),
  FULLTEXT KEY `Word1` (`Word1`),
  FULLTEXT KEY `Word2` (`Word2`),
  FULLTEXT KEY `Word3` (`Word3`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;

CREATE TABLE `seen_tweets` (
  `tweet_id` varchar(20) NOT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`tweet_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

